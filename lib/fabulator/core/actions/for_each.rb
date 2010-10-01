module Fabulator
  module Core
  module Actions
  class ForEach < Fabulator::Structural
    namespace Fabulator::FAB_NS

    attribute :as, :static => true

    contains :sort

    has_select
    has_actions

    def run(context, autovivify = false)
      @context.with(context) do |ctx|
        items = self.select(ctx) #@select.run(ctx)
        res = nil
        ctx.in_context do |c|
          if !@sorts.empty?
            items = items.sort_by{ |i| 
              c.set_var(self.as, i) unless self.as.nil? 
              @sorts.collect{|s| s.run(c.with_root(i)) }.join("\0") 
            }
          end
          res = [ ]
          items.each do |i|
            c.set_var(self.as, i) unless self.as.nil?
            res = res + self.run_actions(c.with_root(i))
          end
        end
        return res
      end
    end
  end

  class Sort < Fabulator::Action
    namespace Fabulator::FAB_NS
    has_select

    def run(context, autovivify = false)
      (self.select(@context.merge(context)).first.to_s rescue '')
    end
  end

  end
  end
end
