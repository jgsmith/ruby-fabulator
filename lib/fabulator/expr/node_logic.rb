module Fabulator
  module Expr
    module NodeLogic
      def to_s
        self.to([ FAB_NS, 'string' ]).value
      end

      def to_h
        r = { }
        #  :attributes => { },

        r[:name] = self.name unless self.name.nil?
        cs = self.children.collect { |c| c.to_h }
        r[:children] = cs unless cs.empty?
        r[:value] = self.value unless self.value.nil?
        r[:type] = self.vtype.join('') unless self.vtype.nil?

        r
      end

      def to(t)
        if @vtype.nil? || t.nil?
          return self.anon_node(self.value, self.vtype)
        end
        if self.vtype.join('') == t.join('')
          return self
        end
        # see if there's a path between @vtype and t
        #   if so, do the conversion
        #   otherwise, return nil
        path = Fabulator::ActionLib.type_path(self.vtype, t)
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

      def ctx
        return self.roots['data'].ctx if self.roots['data'] != self
        return @e_ctx
      end

      def set_var(n,v)
        return self.roots['data'].set_var(n,v) if self.roots['data'] != self
        if n =~ /^\$?(.*)$/
          @e_ctx[:vars] ||= [ ]
          @e_ctx[:vars][0] ||= { }
          @e_ctx[:vars][0][$1] = v
        end
      end

      def get_var(n)
        return self.roots['data'].get_var(n) if self.roots['data'] && self.roots['data'] != self
        @e_ctx[:vars] ||= [ ]
        @e_ctx[:vars].each do |vs|
          return vs[n] if vs.has_key?(n)
        end
        return nil
      end

      def push_var_ctx
        return self.roots['data'].push_var_ctx if self.roots['data'] && self.roots['data'] != self
        @e_ctx[:vars] ||= [ ]
        @e_ctx[:vars].unshift { }
      end

      def pop_var_ctx
        return self.roots['data'].pop_var_ctx if self.roots['data'] && self.roots['data'] != self
        @e_ctx[:vars] ||= [ ]
        @e_ctx[:vars].shift
      end

      def in_context(&block)
        self.push_var_ctx
        r = nil
        begin
          r = yield
        ensure
          self.pop_var_ctx
        end
        r
      end

      def path
        if self.parent.nil? || self.parent == self
          return self.axis + '::'
        else
          return self.parent.path + '/' + self.name
        end
      end

      def copy(c)
        self.value = c.value
        self.vtype = c.vtype
        # TODO: attributes
        c.children.each do |cc|
          n = self.create_child(cc.name, cc.value)
          n.copy(cc)
        end
      end

      def empty?
        self.value.nil? && self.children.empty?
      end
 
      def set_value(p, v)
        if p.is_a?(String) || v.is_a?(String)
          parser = Fabulator::Expr::Parser.new
          p = parser.parse(p) if p.is_a?(String)
          v = parser.parse(v) if v.is_a?(String)
        end
 
        return [] if p.nil?
 
        p = [ p ] unless p.is_a?(Array)
 
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

      def eval_expression(selection, ns = { })
        self.push_var_ctx
        if selection.is_a?(String)
          p = Fabulator::Expr::Parser.new
          selection = p.parse(selection, ns)
        end

        if selection.nil?
          res = [ ]
        else
          # run selection against current context
          res = selection.run(self)
        end
        self.pop_var_ctx
        return res
      end

      def traverse_path(path, autovivify = false)
        return [ self ] if path.nil? || path.is_a?(Array) && path.empty?

        path = [ path ] unless path.is_a?(Array)

        current = [ self ]

        path.each do |c|
          set = [ ]
          current.each do |cc|
            if c.is_a?(String)
              cset = cc.children(c)
            else
              cc.push_var_ctx
              cset = c.run(cc, autovivify)
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

      def get_values(ln = nil)
        return [] if ln.nil?
        self.children(ln).collect{ |c| c.value} - [ nil ]
      end

      def root(a = nil)
        if(a.nil? || a == '')
          a = self.axis
        end
        if a.nil? || a == '' || self.roots[a].nil?
          p = self
          while !p.parent.nil? && p.parent != self
            p = p.parent
          end
          self.roots[a] = p unless a.nil? || a == ''
          return p
        else
          self.roots[a.nil? ? self.axis : a]
        end
      end   

    end
  end
end
