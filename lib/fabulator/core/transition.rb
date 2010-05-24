module Fabulator
  module Core
  class Transition
    attr_accessor :state, :validations, :tags

    def initialize
      @state = nil
      @tags = nil
      @groups = { }
      @params = [ ]
      @actions = nil
    end

    def compile_xml(xml, c_attrs = { })
      inheriting = !@state.nil?

      if !inheriting
        @state = xml.attributes.get_attribute_ns(FAB_NS, 'view').value
        @tags = (xml.attributes.get_attribute_ns(FAB_NS, 'tag').value rescue '').split(/\s+/)
      end

      attrs = ActionLib.collect_attributes(c_attrs, xml)

        # TODO: figure out some way to reference inherited actions
        #   figure out 'super' vs. 'inner' -- only supporting 'super'
        #   for now
      ActionLib.with_super(@actions) do
        t = ActionLib.compile_actions(xml, attrs)
        @actions = t if @actions.nil? || !t.is_noop?
      end
      parser = Fabulator::Expr::Parser.new

      xml.each_element do |e|
        next unless e.namespaces.namespace.href == FAB_NS
        case e.name
# TODO: handle parameters when inheriting
          when 'params':
            p_attrs = ActionLib.collect_attributes(attrs, e)
            @select = ActionLib.get_select(e, '/')

            e.each_element do |ee|
              next unless ee.namespaces.namespace.href == FAB_NS
              case ee.name
                when 'group':
                  if !inheriting
                    g = Group.new.compile_xml(ee, p_attrs)
                    @params << g
                  else
                    tags = (ee.attributes.get_attribute_ns(FAB_NS, 'tag').value rescue '').split(/\s+/)
                  end
                when 'param':
                  if !inheriting
                    p = Parameter.new.compile_xml(ee, p_attrs)
                    @params << p
                  else
                    tags = (ee.attributes.get_attribute_ns(FAB_NS, 'tag').value rescue '').split(/\s+/)
                  end
              end
            end
        end
      end
      self
    end

    def param_names
      (@params.collect{|w| w.param_names}.flatten).uniq
    end

    def validate_params(context,params)
      my_params = params
      my_params.delete('url')
      my_params.delete('action')
      my_params.delete('controller')
      my_params.delete('id')
      param_context = Fabulator::Expr::Node.new(
        'ext',
        context.roots,
        nil,
        []
      )
      context.roots['ext'] = param_context
      param_context.merge_data(my_params)

      filtered = self.apply_filters(@select.nil? ? param_context : @select.run(param_context))

      # 'filtered' has a list of all parameters that have been passed through
      # some kind of filter -- not necessarily ones that have passed a
      # constraint

      res = self.apply_constraints(@select.nil? ? param_context : @select.run(param_context))

      res[:unknown] = [ ]

      res[:invalid].uniq!
      res[:invalid].each do |k|
        res[:valid].delete(k.path)
        res[:unknown].delete(k.path)
      end
      #res[:unknown] = res[:unknown].collect{|k| @select + k}
      res[:unknown].each do |k|
        res[:valid].delete(k)
      end

      res[:score] = (res[:valid].size+1)*(params.size)
      res[:score] = res[:score] / (res[:missing].size + 1)
      res[:score] = res[:score] / (res[:invalid].size + 1)
      res[:score] = res[:score] / (res[:unknown].size + 1)
      return res
    end

    def apply_filters(context)
      @params.each do |p|
        p.apply_filters(context)
      end
    end

    def apply_constraints(context)
      invalid = [ ]
      missing = [ ]
      valid = [ ]
      msgs = [ ]
      @params.each do |p|
        res = p.apply_constraints(context)
        invalid = invalid + res[:invalid]
        missing = missing + res[:missing]
        valid = valid + res[:valid]
        msgs = msgs + res[:messages]
      end
      return { :missing => missing, :invalid => invalid, :valid => valid, :messages => msgs, :unknown => [ ] }
    end

    def run(context)
      # do queries, denials, assertions in the order given
      @actions.run(context)
      return []
    end
  end
  end
end
