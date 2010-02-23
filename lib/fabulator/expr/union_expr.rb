module Fabulator
  module Expr
    class UnionExpr
      def initialize(es)
        @exprs = es
      end

      def run(context, autovivify = false)
        u = [ ]
        @exprs.each do |e|
          u = u + e.run(context, autovivify)
        end
        return u.uniq
      end
    end
  end
end
