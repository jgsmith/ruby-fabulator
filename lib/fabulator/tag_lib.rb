module Fabulator
  class TagLib
    @@action_descriptions = {}
    @@structural_descriptions = {}
    @@structural_classes = {}
    @@function_descriptions = {}
    @@function_args = { }
    @@namespaces = {}
    @@attributes = [ ]
    @@last_description = nil
    @@presentations = { }
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
    def self.structural_descriptions
      @@structural_descriptions
    end
    def self.structural_classes
      @@structural_classes
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
    def self.presentations
      @@presentations
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
    def self.structural_descriptions=(x)
      @@structural_descriptions = x
    end
    def self.structural_classes=(x)
      @@structural_classes = x
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
    def self.presentations=(x)
      @@presentations = x
    end

    def structural_class(nom)
      Fabulator::TagLib.structural_classes[self.class.name][nom.to_sym]
    end

    def self.inherited(base)
      base.extend(ClassMethods)
    end

    def self.type_handler(t)
      (@@types[t[0]][t[1].to_sym] rescue nil)
    end

    def self.find_op(t,o)
      ( self.type_handler(t).get_method(t[0] + o.to_s.upcase) rescue nil )
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
        t = t.vtype.collect{ |i| i.to_s} unless t.is_a?(Array)
        grouped[t.join('')] = t
      end

      grouped = grouped.values

      return grouped.first if grouped.size == 1
     
      # now we unify based on the first two and then adding one each time
      # until we unify all of them
      t1 = grouped.pop
      t2 = grouped.pop
      t1_obj = self.type_handler(t1)
      ut = t1_obj.unify_with_type(t2)
      return nil if ut.nil?
      self.unify_types([ ut[:t] ] + grouped)
    end

    def self.type_path(from, to)
      return [] if from.nil? || to.nil? || from.join('') == to.join('')
      from_obj = self.type_handler(from)
      return [] if from_obj.nil?
      return from_obj.build_conversion_to(to)
    end

    def self.with_super(s, &block)
      @@super ||= []  # not thread safe :-/
      @@super.unshift(s)
      yield
      @@super.shift
    end

    def self.current_super
      return nil if @@super.nil? || @@super.empty?
      return @@super.first
    end

    def compile_action(e, c)
      if self.class.method_defined? "action:#{e.name}"
        send "action:#{e.name}", e, c   #.merge(e)
      end
    end

    def compile_structural(e, c)
      if self.class.method_defined? "structural:#{e.name}"
        send "structural:#{e.name}", e, c
      end
    end

    def action_exists?(nom)
      self.respond_to?("action:#{nom.to_s}")
    end

    def run_function(context, nom, args, depth=0)
      ret = []

      #begin
        case self.function_run_type(nom)
        when :mapping
          ret = args.flatten.collect { |a| send "fctn:#{nom}", context, a }
        when :reduction
          ret = send "fctn:#{nom}", context, args.flatten
        when :consolidation
          if respond_to?("fctn:#{nom}")
            ret = send "fctn:#{nom}", context, args.flatten
          elsif nom =~ /^consolidation:(.*)$/
            ret = send "fctn:#{$1}", context, args.flatten
          else
            ret = [ ]
          end
        else
          ret = send "fctn:#{nom}", context, args
        end
      #rescue => e
      #  raise "function #{nom} raised #{e}"
      #end
      ret = [ ret ] unless ret.is_a?(Array)
      ret = ret.flatten.collect{ |r| 
        if r.is_a?(Fabulator::Expr::Node) 
          r 
        elsif r.is_a?(Hash)
          rr = context.root.anon_node(nil, nil)
          r.each_pair do |k,v|
            rrr = context.root.anon_node(v) #, self.function_return_type(nom))
            rrr.name = k
            rr.add_child(rrr)
          end
          rr
        else
          rt = self.function_return_type(nom)
          if rt.nil?
            context.root.anon_node(r) #, self.function_return_type(nom))
          else
            context.root.anon_node(r,rt)
          end
        end
      }
      ret.flatten
    end

    def function_return_type(name)
      (self.function_descriptions[name.to_sym][:returns] rescue nil)
    end

    def function_run_scaling(name)
      (self.function_descriptions[name.to_sym][:scaling] rescue nil)
    end

    def function_run_type(name)
      r = (self.function_descriptions[name.to_sym][:type] rescue nil)
      if r.nil? && !self.function_descriptions.has_key?(name.to_sym)
        if name =~ /^consolidation:(.*)/
          if function_run_scaling($1) != :flat
            return :consolidation
          end
        end
      end
      r
    end

    def function_args
      @function_args ||= { }
    end

    def run_filter(context, nom)
      send "filter:#{nom}", context
    end

    def run_constraint(context, nom)
      context = [ context ] unless context.is_a?(Array)
      paths = [ [], [] ]
      context.each do |c|
        p = send("constraint:#{nom}", c) 
        paths[0] += p[0]
        paths[1] += p[1]
      end
      return [ (paths[0] - paths[1]).uniq, paths[1].uniq ]
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

    def presentation
      self.class.presentation
    end

    module ClassMethods
      def inherited(subclass)
        subclass.action_descriptions.reverse_merge! self.action_descriptions
        subclass.function_descriptions.reverse_merge! self.function_descriptions
        super
      end
      
      def action_descriptions(hash = nil)
        Fabulator::TagLib.action_descriptions[self.name] ||= (hash ||{})
      end

      def function_descriptions(hash = nil)
        Fabulator::TagLib.action_descriptions[self.name] ||= (hash ||{})
      end
    
      def register_namespace(ns)
        Fabulator::TagLib.namespaces[ns] = self.new
      end

      def namespace(ns)
        Fabulator::TagLib.namespaces[ns] = self.new
      end

      def presentation
        Fabulator::TagLib.presentations[self.name] ||= Fabulator::TagLib::Presentations.new
      end

      def register_attribute(a, options = {})
        ns = nil
        Fabulator::TagLib.namespaces.each_pair do |k,v|
          if v.is_a?(self)
            ns = k
          end
        end
        Fabulator::TagLib.attributes << [ ns, a, options ]
      end

      def get_type(nom)
        ns = nil
        Fabulator::TagLib.namespaces.each_pair do |k,v|
          if v.is_a?(self)
            ns = k
          end
        end
        Fabulator::TagLib.types[ns][nom.to_sym]
      end

      def has_type(nom, &block)
        ns = nil
        Fabulator::TagLib.namespaces.each_pair do |k,v|
          if v.is_a?(self)
            ns = k
          end
        end
        Fabulator::TagLib.types[ns] ||= {}
        Fabulator::TagLib.types[ns][nom.to_sym] ||= Fabulator::TagLib::Type.new([ns, nom.to_sym])

        if block
          Fabulator::TagLib.types[ns][nom.to_sym].instance_eval &block
        end

        mapping nom do |ctx, i|
          ctx.with_root(i).to([ ns, nom.to_s ]).root
        end
      end

      def axis(nom, &block)
        Fabulator::TagLib.axes[nom] = block
      end

      def namespaces
        Fabulator::TagLib.namespaces
      end
  
      def desc(text)
        Fabulator::TagLib.last_description = RedCloth.new(Util.strip_leading_whitespace(text)).to_html
      end
      
      def action(name, klass = nil, &block)
        self.action_descriptions[name.to_sym] = Fabulator::TagLib.last_description if Fabulator::TagLib.last_description
        Fabulator::TagLib.last_description = nil
        if block
          define_method("action:#{name.to_s}", block)
        elsif !klass.nil?
          action(name) { |e,c|
            r = klass.new
            r.compile_xml(e,c)
            r
          }
        end
      end

      def structural(name, klass = nil, &block)
        self.structural_descriptions[name.to_sym] = Fabulator::TagLib.last_description if Fabulator::TagLib.last_description
        Fabulator::TagLib.last_description = nil
        if block
          define_method("structural:#{name.to_s}", block)
        elsif !klass.nil?
          structural(name) { |e,c|
            r = klass.new
            r.compile_xml(e,c)
            r
          }
          Fabulator::TagLib.structural_classes[self.name] ||= {}
          Fabulator::TagLib.structural_classes[self.name][name.to_sym] = klass
        end
      end

      def function(name, returns = nil, takes = nil, &block)
        self.function_descriptions[name.to_sym] = { :returns => returns, :takes => takes }
        self.function_descriptions[name.to_sym][:description] = Fabulator::TagLib.last_description if Fabulator::TagLib.last_description
        #self.function_args[name] = { :return => returns, :takes => takes }
        Fabulator::TagLib.last_description = nil
        define_method("fctn:#{name}", &block)
      end

      def reduction(name, opts = {}, &block)
        self.function_descriptions[name.to_sym] = { :type => :reduction }.merge(opts)
        self.function_descriptions[name.to_sym][:description] = Fabulator::TagLib.last_description if Fabulator::TagLib.last_description
        Fabulator::TagLib.last_description = nil
        define_method("fctn:#{name}", &block)
        cons = self.function_descriptions[name.to_sym][:consolidation]
        if !cons.nil?
          Fabulator::TagLib.last_description = self.function_descriptions[name.to_sym][:description]
          consolidation name do |ctx, args|
            send "fctn:#{cons}", ctx, args
          end
        end
      end

      def consolidation(name, opts = {}, &block)
        self.function_descriptions[name.to_sym] = { :type => :consolidation }.merge(opts)
        self.function_descriptions[name.to_sym][:description] = Fabulator::TagLib.last_description if Fabulator::TagLib.last_description
        Fabulator::TagLib.last_description = nil
        define_method("fctn:consolidation:#{name}", &block)
      end

      def mapping(name, opts = {}, &block)
        name = name.to_sym
        self.function_descriptions[name] = { :type => :mapping }.merge(opts)
        self.function_descriptions[name][:description] = Fabulator::TagLib.last_description if Fabulator::TagLib.last_description
        Fabulator::TagLib.last_description = nil
        define_method("fctn:#{name.to_s}", &block)
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

      def presentations(&block)
        self.presentation.instance_eval &block
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
