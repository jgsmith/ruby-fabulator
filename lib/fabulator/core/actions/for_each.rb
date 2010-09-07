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

  class Considering < Fabulator::Action
    namespace Fabulator::FAB_NS
    attribute :as, :static => true
    has_select
    has_actions

    def run(context, autovivify = false)
      return [] if @select.nil?
      res = [ ]
      @context.with(context) do |ctx|
        c = self.select(ctx)
        root = nil
        if self.as.nil?
          if c.size == 1
            root = c.first
          else
            root = Fabulator::Expr::Node.new('data', context.root.roots, nil, c)
          end
          res = self.run_actions(ctx.with_root(root))
        else
          ctx.in_context do |ctx2|
            ctx2.set_var(self.as, c)
            res = self.run_actions(ctx2)
          end
        end
      end
      res
    end
  end

  class While < Fabulator::Action
    namespace Fabulator::FAB_NS
    attribute :test, :eval => true, :static => false
    attribute :limit, :default => 1000
    has_actions

    def run(context, autovivify = false)
      res = [ ]
      counter = 0
      @context.with(context) do |ctx|
        lim = self.limit(ctx) #@limit.nil? ? 1000 : @limit.run(ctx).first.value
        while counter < lim && (!!self.test(ctx).first.value rescue false)
          res = res + self.run_actions(ctx)
        end
      end
      res
    end
  end
  end
  end
end
