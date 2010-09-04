module Fabulator
  module Core
  module Actions
  class Choose < Fabulator::Structural

    namespace FAB_NS

    contains :when, :as => :choices
    contains :otherwise, :as => :default

    def run(context, autovivify = false)
      @context.with(context) do |ctx|
        @choices.each do |c|
          if c.run_test(ctx)
            return c.run(ctx)
          end
        end
        return @default.first.run(ctx) unless @default.empty?
        return []
      end
    end
  end

  class When < Fabulator::Action
    namespace Fabulator::FAB_NS
    attribute :test, :eval => true, :static => false

    has_actions

    def run_test(context)
      return true if @test.nil?
      result = @test.run(@context.merge(context)).collect{ |a| !!a.value }
      return false if result.nil? || result.empty? || !result.include?(true)
      return true
    end

    def run(context, autovivify = false)
      return @actions.run(@context.merge(context))
    end
  end

  class If < Fabulator::Action
    namespace Fabulator::FAB_NS
    attribute :test, :eval => true, :static => false

    has_actions

    def run(context, autovivify = false)
      return [ ] if @test.nil?
      @context.with(context) do |ctx|
        test_res = @test.run(ctx).collect{ |a| !!a.value }
        return [ ] if test_res.nil? || test_res.empty? || !test_res.include?(true)
        return @actions.run(ctx)
      end
    end
  end

  class Block < Fabulator::Action

    namespace Fabulator::FAB_NS
    has_actions

    def run(context, autovivify = false)
       return @actions.run(@context.merge(context),autovivify)
    end
  end

  class Goto < Fabulator::Action
    namespace Fabulator::FAB_NS
    attribute :test, :eval => true, :static => false
    attribute :state, :static => true

    def run(context, autovivify = false)
      raise Fabulator::StateChangeException, @state, caller if @test.nil?
      test_res = @test.run(@context.merge(context)).collect{ |a| !!a.value }
      return [ ] if test_res.nil? || test_res.empty? || !test_res.include?(true)
      raise Fabulator::StateChangeException, @state, caller
    end
  end

  class Catch < Fabulator::Action
    namespace Fabulator::FAB_NS
    attribute :test, :eval => true, :static => false
    attribute :as, :static => true

    has_actions

    def run_test(context)
      return true if @test.nil?
      @context.with(context) do |ctx|
        ctx.set_var(@as, context) if @as
        result = @test.run(context).collect{ |a| !!a.value }
        return false if result.nil? || result.empty? || !result.include?(true)
        return true
      end
    end

    def run(context, autovivify = false)
      @context.with(context) do |ctx|
        ctx.set_var(@as, context) if @as
        return @actions.run(context)
      end
    end
  end

  class Raise < Fabulator::Action
 
    namespace Fabulator::FAB_NS
    attribute :test, :eval => true, :static => false
    has_actions

    def run(context, autovivify = false)
      @context.with(context) do |ctx|
        select = ctx.get_select
        if !@test.nil?
          test_res = @test.run(ctx).collect{ |a| !!a.value }
          return [ ] if test_res.nil? || test_res.empty? || !test_res.include?(true)
        end
        res = [ ]
        if select.nil? && !@actions.nil?
          res = @actions.run(ctx, autovivify)
        elsif !select.nil?
          res = select.run(ctx, autovivify)
        else
          raise ctx   # default if <raise/> with no attributes
        end

        return [ ] if res.empty?

        raise Fabulator::Expr::Exception.new(res.first)
      end
    end
  end

  class Super < Fabulator::Action
    namespace Fabulator::FAB_NS
    has_select
    has_actions :super

    def run(context, autovivify = false)
      return [] if @actions.nil?

      @context.with(context) do |ctx|
        new_context = @select.run(ctx,autovivify)

        new_context = [ new_context ] unless new_context.is_a?(Array)

        return new_context.collect { |c| @actions.run(ctx.with_root(c), autovivify) }.flatten
      end
    end
  end

  end
  end
end
