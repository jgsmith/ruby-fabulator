module Fabulator
  module Core
  class Filter < Fabulator::Action
    namespace Fabulator::FAB_NS
    attribute :name, :static => true
    
    def run(context)
      filtered = [ ]
      @context.with(context) do |ctx|
        filter_type = @name.split(/:/,2)
        ns = nil
        name = nil
        if filter_type.size == 2
          ns = @context.get_ns(filter_type[0])
          name = filter_type[1]
        else
          ns = FAB_NS
          name = filter_type[0]
        end

        ctx.run_filter(ns, name)
        filtered << ctx.root.path
      end
      return filtered
    end
  end
  end
end
