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
        items = @select.run(ctx)
        res = nil
        ctx.in_context do |c|
          if !@sorts.empty?
            items = items.sort_by{ |i| 
              c.set_var(@as, i) unless @as.nil? 
              @sorts.collect{|s| s.run(c.with_root(i)) }.join("\0") 
            }
          end
          res = [ ]
          items.each do |i|
            c.set_var(@as, i) unless @as.nil?
            res = res + @actions.run(c.with_root(i))
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
      (@select.run(@context.merge(context)).first.to_s rescue '')
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
        c = @select.run(ctx)
        root = nil
        if @as.nil?
          if c.size == 1
            root = c.first
          else
            root = Fabulator::Expr::Node.new('data', context.root.roots, nil, c)
          end
          res = @actions.run(ctx.with_root(root))
        else
          ctx.in_context do |ctx2|
            ctx2.set_var(@as, c)
            res = @actions.run(ctx2)
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
        lim = @limit.nil? ? 1000 : @limit.run(ctx).first.value
        while counter < @limit && (!!@test.run(ctx).first.value rescue false)
          res = res + @actions.run(ctx)
        end
      end
      res
    end
  end
  end
  end
end
