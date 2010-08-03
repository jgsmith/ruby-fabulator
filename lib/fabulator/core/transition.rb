module Fabulator
  module Core
  class Transition < Fabulator::Action
    attr_accessor :state, :validations, :tags

    namespace Fabulator::FAB_NS
    attribute :view, :as => :lstate, :static => true
    attribute :tag,  :as => :ltags,  :static => true, :default => ''

    def initialize
      @state = nil
      @tags = nil
      @groups = { }
      @params = [ ]
      @actions = nil
    end

    def compile_xml(xml, ctx)
      super

      inheriting = !@state.nil?

      if !inheriting
        @state = @lstate
        @tags = @ltags
      end

        # TODO: figure out some way to reference inherited actions
        #   figure out 'super' vs. 'inner' -- only supporting 'super'
        #   for now
      ActionLib.with_super(@actions) do
        t = @context.compile_actions(xml)
        @actions = t if @actions.nil? || !t.is_noop?
      end
      parser = Fabulator::Expr::Parser.new

      xml.each_element do |e|
        next unless e.namespaces.namespace.href == FAB_NS
        case e.name
# TODO: handle parameters when inheriting
          when 'params':
            p_ctx = @context.merge(e)
            @select = p_ctx.get_select('/')

            e.each_element do |ee|
              next unless ee.namespaces.namespace.href == FAB_NS
              case ee.name
                when 'group':
                  if !inheriting
                    g = Group.new.compile_xml(ee, p_ctx)
                    @params << g
                  else
                    tags = (ee.attributes.get_attribute_ns(FAB_NS, 'tag').value rescue '').split(/\s+/)
                  end
                when 'param':
                  if !inheriting
                    p = Parameter.new.compile_xml(ee, p_ctx)
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
      ctx = @context.merge(context)
      my_params = params

      param_context = Fabulator::Expr::Node.new(
        'ext',
        ctx.root.roots,
        nil,
        []
      )
      ctx.root.roots['ext'] = param_context
      p_ctx = ctx.with_root(param_context)
      p_ctx.merge_data(my_params)

      if @select.nil?
        self.apply_filters(p_ctx)
      else
        @select.run(p_ctx).each{ |c| self.apply_filters(p_ctx.with_root(c)) }
      end

      res = {
        :unknown => [ ],
        :valid => [ ],
        :invalid => [ ],
        :missing => [ ],
        :messages => [ ],
      }

      if @select.nil?
        rr = self.apply_constraints(p_ctx)
        res[:invalid] += rr[:invalid]
        res[:valid] += rr[:valid]
        res[:unknown] += rr[:unknown]
        res[:messages] += rr[:messages]
      else
        @select.run(p_ctx).each do |c|
          rr = self.apply_constraints(p_ctx.with_root(c))
          res[:invalid] += rr[:invalid]
          res[:valid] += rr[:valid]
          res[:unknown] += rr[:unknown]
          res[:messages] += rr[:messages]
        end
      end

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

    def apply_filters(ctx)
      @params.collect { |p|
        p.apply_filters(ctx)
      }.flatten
    end

    def apply_constraints(ctx)
      invalid = [ ]
      missing = [ ]
      valid = [ ]
      msgs = [ ]
      @params.each do |p|
        res = p.apply_constraints(ctx)
        invalid = invalid + res[:invalid]
        missing = missing + res[:missing]
        valid = valid + res[:valid]
        msgs = msgs + res[:messages]
      end
      return { :missing => missing, :invalid => invalid, :valid => valid, :messages => msgs, :unknown => [ ] }
    end

    def run(context)
      # do queries, denials, assertions in the order given
      @actions.run(@context.merge(context))
      return []
    end
  end
  end
end
