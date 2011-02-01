#
# Provides functional support -- not quite closures (yet)
#
module Fabulator
  module Lib
    class Action < Fabulator::Structural
      attr_accessor :attributes
      attr_accessor :namespace

      namespace FAB_LIB_NS

      attribute :name, :static => true
      attribute 'has-actions', :static => true, :as => :has_actions, :type => :boolean
      attribute 'has-select', :static => true, :as => :has_select, :type => :boolean

      contains :attribute

      has_actions

      def compile_action(e, context)
        ret = nil
        context.with(e) do |ctx|
          ret = ActionRef.new([ e.namespace.href, e.name ], ctx, ctx.compile_actions(e))
        end
        ret
      end

      def has_select?
        @has_select
      end
    end

    class ActionRef
      def initialize(defining_action, context, actions = nil)
        @context = context
        @action = defining_action
        @actions = actions
        @static_attributes = { }
        @context.get_action(@action.first, @action.last).attributes.select{ |a| a.is_static? }.each do |a|
          @static_attributes[a.name] = a.value(@context)
        end
      end

      def run(context, autovivify = false)
        ret = [ ]
        @context.with(context) do |ctx|
          @static_attributes.each_pair do |p,v|
            ctx.set_var(p, v)
          end
# These can be passed to f:eval to get their value
          action = ctx.get_action(@action.first, @action.last)
          action.attributes.select{ |a| !a.is_static? }.each do |attr|
            ctx.set_var(attr.name, attr.value(@context))
          end
          # we can f:eval($actions) in whatever current context we have
          if action.has_actions?
            @actions.use_context(context)
            ctx.set_var('actions', ctx.root.anon_node( @actions, [ FAB_NS, 'expression' ]))
          end
          if action.has_select?
            v = @context.attribute(Fabulator::FAB_NS, 'select', { :eval => true })

            ctx.set_var('select', ctx.root.anon_node( v, [ FAB_NS, 'expression' ]))
          end
          ret = action.run(ctx)
        end
        ret
      end
    end
  end
end
