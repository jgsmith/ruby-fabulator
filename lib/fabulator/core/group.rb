module Fabulator
  module Core
  class Group
    attr_accessor :name, :params, :tags

    def initialize
      @params = [ ]
      @constraints = [ ]
      @filters = [ ]
      @required_params = [ ]
      @tags = [ ]
    end

    def compile_xml(xml, c_attrs)
      @select = ActionLib.get_local_attr(xml, FAB_NS, 'select', { :eval => true })

      attrs = ActionLib.collect_attributes(c_attrs, xml)
      xml.each_element do |e|
        next unless e.namespaces.namespace.href == FAB_NS

        case e.name
          when 'param':
            v = Parameter.new.compile_xml(e,attrs)
            @params << v
            @required_params = @required_params + v.names if v.required?
          when 'group':
            v = Group.new.compile_xml(e,attrs)
            @params << v
            @required_params = @required_params + v.required_params.collect{ |n| (@name + '/' + n).gsub(/\/+/, '/') }
          when 'constraint':
            @constraints << Constraint.new.compile_xml(e,attrs)
          when 'filter':
            @filters << Filter.new.compile_xml(e,attrs)
        end
      end
      self
    end

    def apply_filters(context)
      roots = self.get_context(context)
      filtered = [ ]

      roots.each do |root|
        @params.each do |param|
          p_ctx = param.get_context(root)
          if !p_ctx.nil? && !p_ctx.empty?
            p_ctx.each do |p|
              @filters.each do |f|
                filtered = filtered + f.apply_filter(p)
              end
            end
          end
          filtered = filtered + param.apply_filters(root)
        end
      end
      filtered.uniq
    end

    def apply_constraints(context)
      res = { :missing => [], :invalid => [], :valid => [], :messages => [] }
      passed = [ ]
      failed = [ ]
      roots = self.get_context(context)
      roots.each do |root|
        @params.each do |param|
          p_ctx = param.get_context(root)
          if !p_ctx.nil? && !p_ctx.empty?
            p_ctx.each do |p|
              @constraints.each do |c|
                r = c.test_constraint(p)
                passed += r[0]
                failed += r[1]
              end
              p_res = param.apply_constraints(p)
              res[:messages] += p_res[:messages]
              failed += p_res[:invalid]
              passed += p_res[:valid]
              res[:missing] += p_res[:missing]
            end
          end
        end
      end
      res[:invalid] = failed.unique
      res[:valid] = (passed - failed).unique
      res[:messages] = res[:messages].unique
      res[:missing] = (res[:missing] - passed).unique
      res
    end


    def get_context(context)
      @select.nil? ? [ context ] : @select.run(context)
    end

    def test_constraints(context)
      passed = [ ]
      failed = [ ]
      roots = self.get_context(context)
      roots.each do |root|
        @params.each do |param|
          p_ctx = param.get_context(root)
          if !p_ctx.nil? && !p_ctx.empty?
            p_ctx.each do |p|
              @constraints.each do |c|
                r = c.test_constraint(p)
                passed += r[0]
                failed += r[1]
              end
            end
          end
        end
      end
      if failed.empty?
        return [ passed.unique, [] ]
      else
        return [ (passed - failed).unique, failed ]
      end
    end
  end
  end
end
