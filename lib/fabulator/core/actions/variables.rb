module Fabulator
  module Core
  module Actions
  class ValueOf < Fabulator::Action
    namespace Fabulator::FAB_NS
    has_select

    def run(context, autovivify = false)
      @select.run(@context.merge(context), autovivify)
    end
  end

  class Value < Fabulator::Action
    attr_accessor :select, :name

    namespace Fabulator::FAB_NS
    attribute :path, :static => true
    has_select nil
    has_actions

    def run(context, autovivify = false)
      @context.with(context) do |ctx|
        ctx.set_value(self.path, @select.nil? ? @actions : @select )
      end
    end
  end

  class Variable < Fabulator::Action
    namespace Fabulator::FAB_NS
    attribute :name, :eval => false, :static => true
    has_select
    has_actions

    def run(context, autovivify = false)
      return [] if self.name.nil?
      res = [ ]
      @context.with(context) do |ctx|
        if @select
          res = self.select(ctx)
        else
          res = self.run_actions(ctx)
        end
      end
      context.set_var(self.name, res)
      res
    end
  end
  end
  end
end
