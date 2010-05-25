module Fabulator
  module Core
  # admin interface allows managing of constraints and filters
  class Constraint
    def compile_xml(xml, c_attrs = { })
      @constraints = [ ]
      @values = [ ]
      @params = [ ]
      @attributes = { }
      @select = nil
      attrs = ActionLib.collect_attributes(c_attrs, xml)
      @inverted = ActionLib.get_local_attr(xml, FAB_NS, 'invert', { :default => 'false' })

      parser = Fabulator::Expr::Parser.new

      @select = ActionLib.get_local_attr(xml, FAB_NS, 'select', { :eval => true })

      if xml.name == 'value'
        @c_type = 'any'
        @values << xml.content
      else
        #@c_type = xml.attributes.get_attribute_ns(FAB_NS, 'name').value
        @c_type = ActionLib.get_local_attr(xml, FAB_NS, 'name')

        xml.each_attr do |attr|
          next unless attr.ns.href == FAB_NS
          next if attr.name == 'name' || attr.name == 'invert'
          @attributes[attr.name] = attr.value
        end
        xml.each_element do |e|
          next unless e.namespaces.namespace.href == FAB_NS
          case e.name
            when 'param':
              pname = (e.get_attribute_ns(FAB_NS, 'name').value rescue nil)
              if !pname.nil?
                v = ActionLib.get_local_attr(e, FAB_NS, 'value', {
                      :default => ActionLib.get_local_attr(
                        e, FAB_NS, 'select', { :eval => true }
                      )
                    })
                #v = (e.get_attribute_ns(FAB_NS, 'value').value rescue nil)
                #if v.nil?
                #  v = ActionLib.get_local_attr(e, FAB_NS, 'select', { :eval => true })
                #  #v = (e.get_attribute_ns(FAB_NS, 'select').value rescue nil)
                #  #if !v.nil?
                #  #  v = parser.parse(v, xml)
                #  #end
                #end
              end
              @params[pname] = v unless pname.nil? || v.nil?
            when 'constraint':
              @constraints << Constraint.new.compile_xml(e, attrs)
            when 'value':
              v = ActionLib.get_local_attr(e, FAB_NS, 'select', { :eval => true })
              #v = (e.get_attribute_ns(FAB_NS, 'select').value rescue nil)
              if v.nil?
                v = e.content
              end
              @values << v unless v.nil?
          end
        end
      end
      self
    end

    def error_message(context)
      "#{context.path} does not pass the constraint"
    end

    def test_constraint(context)
      # do special ones first
      context = [ context ] unless context.is_a?(Array)
      paths = [ context.collect{|c| c.path }, [] ]
      inv = (@inverted.run.first.value rescue 'false')
      inv = (inv == 'true' || inv == 'yes') ? true : false
      @sense = !inv ? Proc.new { |r| r } : Proc.new { |r| r.reverse }
      @not_sense = inv ? Proc.new { |r| r } : Proc.new { |r| r.reverse }
      case @c_type
        when nil, '':
          return @sense.call(paths) if @select.nil?
          opts = context.collect{|c| @select.run(c).collect { |o| o.to_s } }.flatten
          context.each do |c|
            if !opts.include?(c.to_s)
              paths[0] -= [ c.path ]
              paths[1] += [ c.path ]
            end
          end
          return @sense.call(paths)
        when 'all':
          # we have enclosed constraints
          @constraints.each do |c|
            r = c.test_constraint(context)
            return @sense.call(r) unless r[1].empty?
          end
          return @not_sense.call(r)
        when 'any':
          if @values.empty?
            @constraints.each do |c|
              r = c.test_constraint(context)
              return @not_sense.call(r) if r[1].empty?
              #return !@sense if c.test_constraint(params,fields)
            end
            return @sense.call(r)
          else
            calc_values = [ ]
            @values.each do |v|
              if v.is_a?(String)
                calc_values << v
              else
                calc_values = calc_values + v.run(context).collect{ |i| i.value }
              end
            end
            context.each do |c|
              if !calc_values.include?(c.value)
                paths[0] -= [ c.path ]
                paths[1] += [ c.path ]
              end
            end
            return @sense.call(paths)
          end
        when 'range':
          fl = (@params['floor'].run(context) rescue nil)
          ce = (@params['ceiling'].run(context) rescue nil)
          context.each do |c|
            if !fl.nil? && fl > c.value || !ce.nil? && ce < c.value
              paths[0] -= [ c.path ]
              paths[1] += [ c.path ]
            end
          end
          return @sense.call(paths)
        else
          #c = FabulatorConstraint.find_by_name(@c_type) rescue nil
          #return @sense if c.nil?
          #return @sense if c.run_constraint(context)
          return @not_sense.call([ [ context.path ], [] ] )
      end
    end
  end
  end
end
