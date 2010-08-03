module Fabulator
  module Expr
    class IfExpr
      def initialize(t, a, b)
        @test = t
        @then_expr = a
        @else_expr = b
      end

      def run(context, autovivify = false)
        res = @test.run(context.merge)

        if res.nil? || res.empty? || !res.first.value
          res = @else_expr.nil? ? [] : @else_expr.run(context.merge, autovivify)
        else
          res = @then_expr.run(context.merge, autovivify)
        end
        return res
      end
    end
  end
end
