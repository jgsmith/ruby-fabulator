module Fabulator
  module Core
  class Constraint < Fabulator::Action

    namespace Fabulator::FAB_NS
    attribute :invert, :static => true, :default => 'false'
    attribute :name, :as => :c_type, :static => true
    has_select

    def compile_xml(xml, ctx)
      super
      @constraints = [ ]
      @values = [ ]
      @params = [ ]
      @attributes = { }

      if xml.name == 'value'
        @c_type = 'any'
        @values << xml.content
      else
        xml.each_attr do |attr|
          next unless attr.ns.href == FAB_NS
          next if attr.name == 'name' || attr.name == 'invert'
          @attributes[attr.name] = attr.value
        end
        xml.each_element do |e|
          next unless e.namespaces.namespace.href == FAB_NS
          e_ctx = @context.merge(e)
          case e.name
            when 'param':
              pname = e_ctx.attribute(FAB_NS, 'name') # (e.get_attribute_ns(FAB_NS, 'name').value rescue nil)
              if !pname.nil?
                v = e_ctx.attribute(FAB_NS, 'value', { :default => e_ctx.get_select })
                @params[pname] = v unless v.nil?
              end
            when 'constraint':
              @constraints << Constraint.new.compile_xml(e, @context)
            when 'value':
              v = e_ctx.get_select
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
      @context.with(context) do |ctx|
        paths = [ [ ctx.root.path ], [] ]
        r = paths

        inv = (@invert == 'true' || @invert == 'yes') ? true : false
        sense = !inv ? Proc.new { |r| r } : Proc.new { |r| r.reverse }
        not_sense = inv ? Proc.new { |r| r } : Proc.new { |r| r.reverse }

        case @c_type
          when nil, '':
            return sense.call(paths) if select.nil?
            opts = @select.run(ctx).collect { |o| o.to_s } 
            if !opts.include?(ctx.root.to_s)
              paths[0] -= [ ctx.root.path ]
              paths[1] += [ ctx.root.path ]
            end
            return sense.call(paths)
          when 'all':
            # we have enclosed constraints
            @constraints.each do |c|
              r = c.test_constraint(ctx)
              return sense.call(r) unless r[1].empty?
            end
            return not_sense.call(r)
          when 'any':
            if @values.empty?
              @constraints.each do |c|
                r = c.test_constraint(ctx)
                return not_sense.call(r) if r[1].empty?
              end
              return sense.call(r)
            else
              calc_values = [ ]
              @values.each do |v|
                if v.is_a?(String)
                  calc_values << v
                else
                  calc_values = calc_values + v.run(ctx).collect{ |i| i.value }
                end
              end
              if !calc_values.include?(ctx.root.value)
                paths[0] -= [ ctx.root.path ]
                paths[1] += [ ctx.root.path ]
              end
              return sense.call(paths)
            end
          when 'range':
            fl = (@params['floor'].run(ctx) rescue nil)
            ce = (@params['ceiling'].run(ctx) rescue nil)
            if !fl.nil? && fl > c.value || !ce.nil? && ce < c.value
              paths[0] -= [ c.path ]
              paths[1] += [ c.path ]
            end
            return sense.call(r)
          else
            return not_sense.call(r)
        end
      end
    end
  end
  end
end
