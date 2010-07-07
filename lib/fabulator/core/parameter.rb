module Fabulator
  module Core
  class Parameter
    attr_accessor :name

    def required?
      @required
    end

    def param_names
      [ @name ]
    end

    def compile_xml(xml, c_attrs = { })
      @name = xml.attributes.get_attribute_ns(FAB_NS, 'name').value
      @constraints = [ ]
      @filters = [ ]
      @required = (xml.attributes.get_attribute_ns(FAB_NS, 'required').value rescue 'false')
      attrs = ActionLib.collect_attributes(c_attrs, xml)

      case @required.downcase
        when 'yes':
          @required = true
        when 'true':
          @required = true
        when 'no':
          @required = false
        when 'false':
          @required = false
      end

      xml.each_element do |e|
        next unless e.namespaces.namespace.href == FAB_NS
        case e.name
          when 'constraint':
            @constraints << Constraint.new.compile_xml(e, attrs)
          when 'filter':
            @filters << Filter.new.compile_xml(e, attrs)
          when 'value':
            @constraints << Constraint.new.compile_xml(e, attrs)
        end
      end
      self
    end

    def get_context(context)
      context = [ context ] unless context.is_a?(Array)
      context.collect{ |c| c.traverse_path(@name) }
    end

    def apply_filters(context)
      filtered = [ ]
      @filters.each do |f|
        context.each do |c|
          filtered = filtered + f.run(c.traverse_path(@name))
        end
      end
      filtered
    end

    def apply_constraints(context)
      res = { :missing => [], :invalid => [], :valid => [], :messages => [] }
      items = context.collect{ |c| c.traverse_path(@name) }.flatten
      if items.empty?
        res[:missing] = context.collect{ |c| (c.path + '/' + @name).gsub(/\/+/, '/')}
      elsif @constraints.empty? # make sure something exists
        res[:valid] = items
      elsif @all_constraints
        @constraints.each do |c|
          items.each do |item|
            r = c.test_constraint(i)
            res[:valid] += r[0]
            if !r[1].empty?
              res[:invalid] += r[1]
              res[:messages] += r[1].collect{ |i| c.error_message(i) }
            end
          end
        end
      else
        items.each do |item|
          passed = @constraints.select {|c| c.test_constraint(item)[1].empty? }
          if passed.empty?
            res[:invalid] << item
            res[:messages] << [ @constraints.collect { |c| c.error_message(item) } ]
          else
            res[:valid] << item
          end
        end
      end

      return res
    end

    def test_constraints(context)
      me = context.traverse_path(@name)
      return [ [ me.collect{ |m| m.path } ], [] ] if @constraints.empty?
      paths = [ [], [] ]
      if @all_constraints
        @constraints.each do |c|
          p =  c.test_constraints(me)
          paths[0] += p[0]
          paths[1] += p[1]
        end
        return [ (paths[0] - paths[1]).uniq, paths[1].uniq ]
      else
        @constraints.each do |c|
          p = c.test_constraints(me)
          paths[0] += p[0]
          paths[1] += p[1]
        end
        return [ paths[0].uniq, (paths[1] - paths[0]).uniq ]
      end
    end
  end
  end
end
