module Fabulator
  module Expr
    class BinExpr
      def initialize(left, right)
        @left = left
        @right = right
      end

      def expr_type(context)
        lt = @left.expr_type(context)
        rt = @right.expr_type(context)
        Fabulator::ActionLib.unify_types([ lt, rt ])
      end

      def run(context, autovivify = false)
        l = @left.run(context, autovivify)
        r = @right.run(context, autovivify)

        l = [ l ] unless l.is_a?(Array)
        r = [ r ] unless r.is_a?(Array)

        res = []

        l.each do |i|
          r.each do |j|
            ut = Fabulator::ActionLib.unify_types([ i.vtype, j.vtype ])
            calc = self.calculate(i.to(ut).value,j.to(ut).value)
            calc = [ calc ] unless calc.is_a?(Array)

            res = res + calc.collect { |c| context.anon_node(c, self.result_type(ut)) }
          end
        end
        return res
      end

      def result_type(t)
        t
      end
    end

    class AddExpr < BinExpr
      def calculate(a,b)
        return nil if a.nil? || b.nil?
        a + b
      end
    end

    class SubExpr < BinExpr
      def calculate(a,b)
        return nil if a.nil? || b.nil?
        a - b
      end
    end

    class BoolBinExpr < BinExpr
      def expr_type(context)
        [ FAB_NS, 'boolean' ]
      end

      def result_type(t)
        [ FAB_NS, 'boolean' ]
      end
    end

    class LtExpr < BoolBinExpr
      def calculate(a,b)
        return nil if a.nil? || b.nil?
        a < b
      end
    end

    class LteExpr < BoolBinExpr
      def calculate(a,b)
        return nil if a.nil? || b.nil?
        a <= b
      end
    end

    class EqExpr < BoolBinExpr
      def calculate(a,b)
        a == b
      end
    end

    class NeqExpr < BoolBinExpr
      def calculate(a,b)
        a != b
      end
    end

    class MpyExpr < BinExpr
      def calculate(a,b)
        return nil if a.nil? || b.nil?
        a * b
      end
    end

    class DivExpr < BinExpr
      def calculate(a,b)
        return nil if b.nil? || a.nil?
        a / b
      end
    end

    class ModExpr < BinExpr
      def calculate(a,b)
        return nil if a.nil? || b.nil?
        a % b
      end
    end

    class RangeExpr < BinExpr
      def expr_type(context)
        [ FAB_NS, 'numeric' ]
      end

      def result_type(t)
        [ FAB_NS, 'numeric' ]
      end

      def calculate(a,b)
        return nil if a.nil? || b.nil?
        if a < b
          r = (a.to_i .. b.to_i).to_a
        else
          r = (b.to_i .. a.to_i).to_a.reverse
        end
        return r
      end
    end
  end
end
