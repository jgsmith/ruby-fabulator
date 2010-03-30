module Fabulator
  module Expr
    class Node
      attr_accessor :axis, :value, :name, :roots, :vtype, :attributes

      def initialize(a,r,v,c,p = nil,f={})
        @roots = r
        @axis = a
        @children = []
        @children = @children + c if c.is_a?(Array)
        @value = v
        @vtype = nil
        @parent = p
        @name = nil
        @e_ctx = f
        @attributes = [ ]

        if @value.is_a?(String)
          @vtype = [ FAB_NS, 'string' ]
        elsif @value.is_a?(Numeric)
          @vtype = [ FAB_NS, 'numeric' ]
        elsif @value.is_a?(TrueClass) || @value.is_a?(FalseClass)
          @vtype = [ FAB_NS, 'boolean' ]
        end
      end

      def set_attribute(k, v)
        if v.is_a?(Fabulator::Expr::Node)
          v = v.clone
        else
          v = Fabulator::Expr::Node.new(self.axis, self.roots, v, [], self)
        end
        v.name = k
        @attributes.delete_if{|a| a.name == k }
        @attributes << v
      end

      def get_attribute(k)
        (@attributes.select{ |a| a.name == k }.first rescue nil)
      end

      def self.new_context_environment
        r = { }
        d = Fabulator::Expr::Node.new('data', r, nil, [])
        r['data'] = d
        d
      end

      def to_s
        self.to([ FAB_NS, 'string' ]).value
      end

      def to_h
        r = { 
          :name => self.name,
          :attributes => { },
          :children => self.children.collect { |c| c.to_h },
        }

        r[:value] = self.value if !self.value.nil?
        r[:type] = self.vtype.join('') if !self.vtype.nil?

        r
      end

      def to(t)
        if @vtype.nil? || t.nil? || @vtype.join('') == t.join('')
          return self.anon_node(@value, @vtype)
        end
        # see if there's a path between @vtype and t
        #   if so, do the conversion
        #   otherwise, return nil
        path = Fabulator::ActionLib.type_path(@vtype, t)
        return self.anon_node(nil,nil) if path.empty?
        v = self
        path.each do |p|
          vv = p.call(v)
          if vv.is_a?(Fabulator::Expr::Node)
            v = vv
          else
            v = self.anon_node(vv)
          end
        end
        v.vtype = t
        return v
      end

      def anon_node(v, t = nil)
        if v.is_a?(Array)
          n = self.class.new(self.axis, self.roots, nil, v.collect{ |vv| self.anon_node(vv, t) })
        else
          n = self.class.new(self.axis, self.roots, v, [])
          n.vtype = t unless t.nil?
        end
        n
      end

      def ctx
        return parent.ctx if @parent && @parent != self
        return @e_ctx
      end

      def set_var(n,v)
        return @roots['data'].set_var(n,v) if @roots['data'] != self
        if n =~ /^\$?(.*)$/
          @e_ctx[:vars] ||= [ ]
          @e_ctx[:vars][0] ||= { }
          @e_ctx[:vars][0][$1] = v
        end
      end

      def get_var(n)
        return parent.get_var(n,v) if @parent && @parent != self
        @e_ctx[:vars] ||= [ ]
        @e_ctx[:vars].each do |vs|
          return vs[n] if vs.has_key?(n)
        end
        return nil
      end

      def push_var_ctx
        return parent.push_var_ctx if @parent && @parent != self
        @e_ctx[:vars] ||= [ ]
        @e_ctx[:vars].unshift { }
      end

      def pop_var_ctx
        return parent.pop_var_ctx if @parent && @parent != self
        @e_ctx[:vars] ||= [ ]
        @e_ctx[:vars].shift
      end

      def copy(c)
        @value = c.value
        @vtype = c.vtype
        c.children.each do |cc|
          pos = self.children(cc.name)
          if pos.size == 1
            pos.first.copy(cc)
          else
            n = self.create_child(cc.name, cc.value)
            n.copy(cc)
          end
        end
      end

      def clone()
        node = self.class.new(@axis, @roots, self.value, [], nil)
        node.name = self.name
        node.attributes = self.attributes.collect { |a| a.clone }
        node
      end

      def create_child(n,v = nil)
        node = self.class.new(@axis, @roots, v, [], self)
        node.name = n
        @children << node
        node
      end

      def path
        if self.parent.nil? || self.parent == self
          return @axis + '::'
        else
          return self.parent.path + '/' + @name
        end
      end

      def empty?
        @value.nil? && @children.empty?
      end

      def set_value(p, v)
        if p.is_a?(String) || v.is_a?(String)
          parser = Fabulator::Expr::Parser.new
          p = parser.parse(p) if p.is_a?(String)
          v = parser.parse(v) if v.is_a?(String)
        end
        return [] if p.nil?
        p = [ p ] if !p.is_a?(Array)
        ret = [ ]
        p.each do |pp|
          tgts = pp.run(self, true)
          src = nil
          if !v.nil?
            src = v.run(self)
          end
          tgts.each do |tgt|
            tgt.prune
            if src.nil? || src.empty?
              tgt.value = nil
              ret << tgt
            elsif src.size == 1
              tgt.copy(src.first)
              ret << tgt
            else
              pp = tgt.parent
              nom = tgt.name
              pp.prune(pp.children(nom))
              src.each do |s|
                tgt = pp.create_child(nom,nil)
                tgt.copy(s)
                ret << tgt
              end
            end
          end
        end
        ret
      end

      def merge_data(d,p = nil)
        # we have a hash or array based on root (r)
        if p.nil?
          root_context = [ self ]
        else
          root_context = self.traverse_path(p,true)
        end
        if root_context.size > 1
          # see if we need to prune
          new_rc = [ ]
          root_context.each do |c|
            if c.children.size == 0 && c.value.nil?
              c.parent.prune(c) if c.parent
            else
              new_rc << c
            end
          end
          if new_rc.size > 0
            raise "Unable to merge data into multiple places simultaneously"
          else
            root_context = new_rc
          end
        else
          root_context = root_context.first
        end
        if d.is_a?(Array)
          node_name = root_context.name
          root_context = root_context.parent
          # get rid of empty children so we don't have problems later
          root_context.children.each do |c|
            if c.children.size == 0 && c.name == node_name && c.value.nil?
              c.parent.prune(c)
            end
          end
          d.each do |i|
            c = root_context.create_child(node_name)
            c.merge_data(i)
          end
        elsif d.is_a?(Hash)
          d.each_pair do |k,v|
            bits = k.split('.')
            c = root_context.traverse_path(bits,true).first
            if v.is_a?(Hash) || v.is_a?(Array)
              c.merge_data(v)
            else
              c.value = v
            end
          end
        else
          c = root_context.parent.create_child(root_context.name, d)
        end
      end

      def eval_expression(selection, ns = { })
        self.push_var_ctx
        if selection.is_a?(String)
          p = Fabulator::Expr::Parser.new
          selection = p.parse(selection, ns)
Rails.logger.info(YAML::dump(selection))
        end

        if selection.nil?
          res = self.class.new(@axis, @roots, @value, [], @roots[@axis])
        else
          # run selection against current context
          res = selection.run(self)
        end
        self.pop_var_ctx
        return res
      end

      def traverse_path(path, autovivify = false)
        #Rails.logger.info("path: [#{path}]")
        return [ self ] if path.nil? || path.is_a?(Array) && path.empty?

        path = [ path ] unless path.is_a?(Array)

        current = [ self ]

        path.each do |c|
          set = [ ]
          current.each do |cc|
            if c.is_a?(String)
              cset = cc.children.select{|c3| c3.name == c }
            else
              #Rails.logger.info("running: [#{c}]")
              cc.push_var_ctx
              cset = c.run(cc)
              cc.pop_var_ctx
            end
            if cset.nil? || cset.empty?
              if autovivify
                if c.is_a?(String)
                  cset = [ cc.create_child(c) ]
                else
                  cset = [ c.create_node(cc) ]
                end
              end
            end
            set = set + cset
          end
          current = set
        end
        return current
      end

      def parent=(p)
        @parent = p
        @axis = p.axis
      end

      def parent
        @parent.nil? ? self : @parent
      end

      def children(n = nil)
        op = ActionLib.find_op(@vtype, :children)
        possible = op.nil? ? @children : op.call(self)
        if n.nil?
          possible
        else
          possible.select{|c| c.name == n }
        end
      end

      def prune(c = nil)
        if c.nil?
          @children = [ ]
        elsif c.is_a?(Array)
          @children = @children - c
        else
          @children = @children - [ c ]
        end
      end

      def get_values(ln = nil)
        return [] if ln.nil?
        self.children.select{|c| c.name == ln}.collect{|c| c.value } - [nil]
      end

      def root(a = nil)
        if(a.nil? || a == '')
          a = @axis
        end
        if a.nil? || a == '' || @roots[a].nil?
          p = self
          while !p.parent.nil? && p.parent != self
            p = p.parent
          end
          return p
        else
          @roots[a.nil? ? @axis : a]
        end
      end

      def add_child(c)
        c.parent.prune(c) if c.parent
        c.parent = self
        c.axis = self.axis
        @children << c
      end
    end

    class CurrentContext
      def initialize
      end

      def run(context, autovivify = false)
        context.nil? ? [] : [ context ]
      end

      def create_node(context)
        context
      end
    end

    class RootContext
      def initialize(axis = nil)
        @axis = axis
      end

      def run(context, autovivify = false)
        c = nil
        if @axis.is_a?(String)
          c = context.root(@axis)
        elsif !@axis.nil?
          c = @axis.run(context, autovivify).first
        else
          c = context.root
        end
        return [ ] if c.nil?
        return [ c ]
      end

      def create_node(context)
        if context.root(@axis).nil?
          context.roots[@axis] = Fabulator::Expr::Node.new(@axis,context.roots,nil,[])
        end
        context.root(@axis)
      end
    end
  end
end
