module Fabulator
  module ActionLib
    @@action_descriptions = {}
    @@function_descriptions = {}
    @@function_args = { }
    @@namespaces = {}
    @@attributes = [ ]
    @@last_description = nil
    @@types = { }
    @@axes = { }

    def self.last_description
      @@last_description
    end
    def self.namespaces
      @@namespaces
    end
    def self.action_descriptions
      @@action_descriptions
    end
    def self.function_description
      @@function_description
    end
    def self.function_args
      @@function_args
    end
    def self.attributes
      @@attributes
    end
    def self.types
      @@types
    end
    def self.axes
      @@axes
    end

    def self.last_description=(x)
      @@last_description = x
    end
    def self.namespaces=(x)
      @@namespaces = x
    end
    def self.action_descriptions=(x)
      @@action_descriptions = x
    end
    def self.function_description=(x)
      @@function_description = x
    end
    def self.function_args=(x)
      @@function_args = x
    end
    def self.attributes=(x)
      @@attributes = x
    end
    def self.types=(x)
      @@types = x
    end
    def self.axes=(x)
      @@axes = x
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.module_eval do
        def self.included(new_base)
          super
          new_base.action_descriptions.merge! self.action_descriptions
          new_base.function_descriptions.merge! self.function_descriptions
          new_base.function_args.merge! self.function_args
          new_base.types.merge! self.types
        end
      end
    end

    def self.find_op(t,o)
      (@@types[t[0]][t[1]][:ops][o] rescue nil)
    end

    # returns nil if no common type can be found
    def self.unify_types(ts)
      # breadth-first search from all ts to find common type that
      # we can convert to.  We have to check all levels each time
      # in case one of the initial types becomes a common type across
      # all ts

      return nil if ts.empty? || ts.include?(nil)

      # now group by types since we only need one of each type for unification
      grouped = { }
      ts.each do |t|
        grouped[t.join('')] = t
      end

      grouped = grouped.values

      return grouped.first if grouped.size == 1
     
      # now we unify based on the first two and then adding one each time
      # until we unify all of them
      t1 = grouped.pop
      t2 = grouped.pop
      ut = self._unify_types(t1, t2)
      return nil if ut.nil?
      self.unify_types([ ut[:t] ] + grouped)
    end

    def self.type_path(from, to)
      return [] if from.nil? || to.nil? || from.join('') == to.join('')
      ut = self._unify_types(from, to, true)
      return [] if ut.nil? || ut[:t].join('') != to.join('')
      return ut[:convert]
    end

    ## TODO: allow unification with values as well so we can have
    #        conversions dependent on the value
    # for example: strings that look like integers can convert to integers
    def self._unify_types(t1, t2, ordered = false)
      return nil if t1.nil? || t2.nil?
      d1 = { t1.join('') => { :t => t1, :w => 1.0, :path => [ t1 ], :convert => [ ] } }
      d2 = { t2.join('') => { :t => t2, :w => 1.0, :path => [ t2 ], :convert => [ ] } }

      added = true
      while added
        added = false
        [d1, d2].each do |d|
          d.keys.each do |t|
            if (@@types[d[t][:t][0]][d[t][:t][1]].has_key?(:to) rescue false)
              @@types[d[t][:t][0]][d[t][:t][1]][:to].each do |conv|
                w = d[t][:w] * conv[:weight]
                conv_key = conv[:type].join('')
                if d.has_key?(conv_key) 
                  if d[conv_key][:w] < w
                    d[conv_key][:w] = w
                    d[conv_key][:path] = d[t][:path] + [ conv[:type] ]
                    d[conv_key][:convert] = d[t][:convert] + [ conv[:convert] ] - [nil]
                  end
                else
                  d[conv_key] = {
                    :t => conv[:type],
                    :w => w,
                    :path => d[t][:path] + [ conv[:type] ],
                    :convert => d[t][:convert] + [ conv[:convert] ] - [ nil ]
                  }
                  added = true
                end
              end
            end
          end
          # go through each type looking for :from
          @@types.keys.each do |ns|
            @@types[ns].each_pair do |ct, cd|
              next if cd[:from].nil?
              to_key = ns + ct
              cd[:from].each do |conv|
                next if conv[:type].nil?
                from_key = conv[:type].join('')
                next if !d.has_key?(from_key)
                w = d[from_key][:w] * conv[:weight]
                if d.has_key?(to_key)
                  if d[to_key][:w] < w
                    d[to_key][:w] = w
                    d[to_key][:path] = d[from_key][:path] + [ conv[:type] ]
                    d[to_key][:convert] = d[from_key][:convert] + [ conv[:convert] ] - [nil]
                  end
                else
                  d[to_key] = {
                    :t => [ns, ct],
                    :w => w * 95 / 100, # favor to over from
                    :path => d[from_key][:path] + [ conv[:type] ],
                    :convert => d[from_key][:convert] + [ conv[:convert] ] - [ nil ]
                  }
                  added = true
                end
              end
            end
          end
        end
        common = d1.keys & d2.keys
        if ordered && common.include?(t2.join(''))
          return d1[t2.join('')]
        elsif !common.empty?
          return d1[common.sort_by{ |c| d1[c][:w] * d2[c][:w] / d1[c][:path].size / d2[c][:path].size }.reverse.first]
        end
      end
      common = d1.keys & d2.keys
      if ordered && common.include?(t2.join(''))
        return d1[t2.join('')]
      elsif !common.empty? 
        return d1[common.sort_by{ |c| d1[c][:w] * d2[c][:w] / d1[c][:path].size / d2[c][:path].size }.reverse.first]
      end
      return nil
    end

    def self.prefix_to_ref(xml, prefix)
      x = xml.namespaces.find_by_prefix(prefix)
      return nil if x.nil?
      x.href
    end

    def self.compile_actions(xml, c_attrs)
      actions = Fabulator::Expr::StatementList.new
      attrs = self.collect_attributes(c_attrs, xml)
      xml.each_element do |e|
        ns = e.namespaces.namespace.href
        next unless Fabulator::ActionLib.namespaces.include?(ns)
        actions.add_statement(Fabulator::ActionLib.namespaces[ns].compile_action(e, attrs)) # rescue nil)
      end
      #actions = actions - [ nil ]
      return actions
    end

    def self.collect_attributes(attrs, xml)
      ret = { }
      attrs.each_pair do |k,v|
        ret[k] = { }
        ret[k].merge!(v)
      end

      parser = Fabulator::Expr::Parser.new

      spaces = { }
      xml.namespaces.each do |ns|
        spaces[ns.prefix] = ns.href
      end
      begin
        spaces[''] = xml.namespaces.default.href
      rescue
      end


      @@attributes.each do |a|
        v = xml.attributes.get_attribute_ns(a[0], a[1])
        if !v.nil?
          ret[a[0]] = {} if ret[a[0]].nil?
          v = v.value
          if !a[2][:expression] && v =~ /^\{(.*)\}$/
            v = (parser.parse($1, spaces) rescue nil)
          else
            v = Fabulator::Expr::Literal.new(v)
          end
          ret[a[0]][a[1]] = v
        end
      end
      ret
    end

    def self.get_attribute(ns, attr, attrs)
      return nil if attrs.nil? || attrs[ns].nil? || attrs[ns].empty? || attrs[ns][attr].nil?
      return attrs[ns][attr]
    end

    def self.get_local_attr(xml, ns, attr, options = {})
      v = (xml.attributes.get_attribute_ns(ns, attr).value rescue nil)
      if v.nil? && !options[:default].nil?
        v = options[:default]
      end

      if !v.nil?
        e = nil
        if !options[:eval] 
          if v =~ /^\{(.*)\}$/
            e = $1
          end
        else
          e = v
        end
        if !e.nil?
          p = Fabulator::Expr::Parser.new
          spaces = { }
          xml.namespaces.each do |ns|
            spaces[ns.prefix] = ns.href
          end
          begin
            spaces[''] = xml.namespaces.default.href
          rescue
          end

          v = p.parse(e, spaces)
        else
          v = Fabulator::Expr::Literal.new(v, [ FAB_NS, v =~ /^\d+$/ ? 'numeric' : v =~ /^\d*\.\d+$/ || v =~ /^\d+\.\d*$/ ? 'numeric' : 'string' ])
        end
      end
      v
    end

    def self.get_select(xml, default)
      self.get_local_attr(xml, FAB_NS, 'select', { :eval => true, :default => default })
    end
 
    def compile_action(e, r)
      #Rails.logger.info("compile_action called with #{YAML::dump(r)}")
      if self.class.method_defined? "action:#{e.name}"
        send "action:#{e.name}", e, Fabulator::ActionLib.collect_attributes(r, e)
      end
    end

    def run_function(context, ns, nom, args)
      ret = []

      begin
        case self.function_run_type(nom)
        when :mapping
          ret = args.flatten.collect { |a| send "fctn:#{nom}", context, a, ns }
        when :reduction
          ret = send "fctn:#{nom}", context, args.flatten, ns
        else
          ret = send "fctn:#{nom}", context, args, ns
        end
      rescue => e
        raise "function #{nom} raised #{e}"
      end
      ret = [ ret ] unless ret.is_a?(Array)
      ret = ret.collect{ |r| 
        if r.is_a?(Fabulator::Expr::Node) 
          r 
        elsif r.is_a?(Hash)
          rr = context.anon_node(nil, nil)
          r.each_pair do |k,v|
            rrr = context.anon_node(v, self.function_return_type(nom))
            rrr.name = k
            rr.add_child(rrr)
          end
          rr
        else
          context.anon_node(r, self.function_return_type(nom))
        end
      }
      ret.flatten
    end

    def function_return_type(name)
      (self.function_descriptions[name][:returns] rescue nil)
    end

    def function_run_type(name)
      (self.function_descriptions[name][:type] rescue nil)
    end

    def function_args
      @function_args ||= { }
    end

    def run_filter(context, nom)
      send "filter:#{nom}", context
    end

    def run_constraint(context, nom)
      send "constraint:#{nom}", context
    end

    def action_descriptions(hash=nil)
      self.class.action_descriptions hash
    end

    def function_descriptions(hash=nil)
      self.class.function_descriptions hash
    end

    def function_args(hash=nil)
      self.class.function_args hash
    end

    module ClassMethods
      def inherited(subclass)
        subclass.action_descriptions.reverse_merge! self.action_descriptions
        subclass.function_descriptions.reverse_merge! self.function_descriptions
        super
      end
      
      def action_descriptions(hash = nil)
        Fabulator::ActionLib.action_descriptions[self.name] ||= (hash ||{})
      end

      def function_descriptions(hash = nil)
        Fabulator::ActionLib.action_descriptions[self.name] ||= (hash ||{})
      end
    
      def register_namespace(ns)
        Fabulator::ActionLib.namespaces[ns] = self.new
      end

      def register_attribute(a, options = {})
        ns = nil
        Fabulator::ActionLib.namespaces.each_pair do |k,v|
          if v.is_a?(self)
            ns = k
          end
        end
        Fabulator::ActionLib.attributes << [ ns, a, options ]
      end

      def register_type(nom, options={})
        ns = nil
        Fabulator::ActionLib.namespaces.each_pair do |k,v|
          if v.is_a?(self)
            ns = k
          end
        end
        Fabulator::ActionLib.types[ns] ||= {}
        Fabulator::ActionLib.types[ns][nom] = options

        function nom do |ctx, args, nss|
          args[0].collect { |i|
            i.to([ ns, nom ])
          }
        end
      end

      def axis(nom, &block)
        Fabulator::ActionLib.axes[nom] = block
      end

      def namespaces
        Fabulator::ActionLib.namespaces
      end
  
      def desc(text)
        Fabulator::ActionLib.last_description = RedCloth.new(Util.strip_leading_whitespace(text)).to_html
      end
      
      def action(name, klass = nil, &block)
        self.action_descriptions[name] = Fabulator::ActionLib.last_description if Fabulator::ActionLib.last_description
        Fabulator::ActionLib.last_description = nil
        if block
          define_method("action:#{name}", &block)
        elsif !klass.nil?
          action(name) { |e,r|
            return klass.new.compile_xml(e,r)
          }
        end
      end

      def function(name, returns = nil, takes = nil, &block)
        self.function_descriptions[name] = { :returns => returns, :takes => takes }
        self.function_descriptions[name][:description] = Fabulator::ActionLib.last_description if Fabulator::ActionLib.last_description
        #self.function_args[name] = { :return => returns, :takes => takes }
        Fabulator::ActionLib.last_description = nil
        define_method("fctn:#{name}", &block)
      end

      def reduction(name, opts = {}, &block)
        self.function_descriptions[name] = { :type => :reduction }.merge(opts)
        self.function_descriptions[name][:description] = Fabulator::ActionLib.last_description if Fabulator::ActionLib.last_description
        Fabulator::ActionLib.last_description = nil
        define_method("fctn:#{name}", &block)
      end

      def mapping(name, opts = {}, &block)
        self.function_descriptions[name] = { :type => :mapping }.merge(opts)
        self.function_descriptions[name][:description] = Fabulator::ActionLib.last_description if Fabulator::ActionLib.last_description
        Fabulator::ActionLib.last_description = nil
        define_method("fctn:#{name}", &block)
      end

      def function_decl(name, expr, ns)
        parser = Fabulator::Expr::Parser.new
        fctn_body = parser.parse(expr, ns)

        function name do |ctx, args, ns|
          res = nil
          ctx.in_context do
            args.size.times do |i|
              ctx.set_var((i+1).to_s, args[i])
            end
            res = fctn_body.run(ctx)
          end
          res
        end
      end

      def filter(name, &block)
        define_method("filter:#{name}", &block)
      end

      def constraint(name, &block)
        define_method("constraint:#{name}", &block)
      end

      def compile_actions(xml, rdf_model)
        actions = [ ]
        xml.each_element do |e|
          ns = e.namespaces.namespace.href
          #Rails.logger.info("Compiling <#{ns}><#{e.name}>")
          next unless Fabulator::ActionLib.namespaces.include?(ns)
          actions << (Fabulator::ActionLib.namespaces[ns].compile_action(e, rdf_model) rescue nil)
          #Rails.logger.info("compile_actions: #{actions}")
        end
        #Rails.logger.info("compile_actions: #{actions}")
        actions = actions - [ nil ]
        #Rails.logger.info("compile_actions returning: #{actions}")
        return actions
      end
  
    end
     
    module Util
      def self.strip_leading_whitespace(text)
        text = text.dup
        text.gsub!("\t", "  ")
        lines = text.split("\n")
        leading = lines.map do |line|
          unless line =~ /^\s*$/
             line.match(/^(\s*)/)[0].length
          else
            nil
          end
        end.compact.min
        lines.inject([]) {|ary, line| ary << line.sub(/^[ ]{#{leading}}/, "")}.join("\n")
      end      
    end
  end
end
