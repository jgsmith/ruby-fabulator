module Fabulator
  module Expr
    class UnaryExpr
      def initialize(e)
        @expr = e
      end

      def run(context, autovivify = false)
        l = @expr.run(context, autovivify)

        l = [ l ] unless l.is_a?(Array)

        l = l.collect { |i| i.value }.uniq - [ nil ]

        return @expr.collect{|e|  Fabulator::Expr::Node.new(
              context.root.axis,
              context.root.roots,
              self.calculate(e),
              []
            ) }
      end
    end

    class NegExpr < UnaryExpr
      def calculate(e)
        e.nil? ? nil : -e
      end
    end
  end
end
