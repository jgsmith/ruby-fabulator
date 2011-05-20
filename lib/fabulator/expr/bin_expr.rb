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
        Fabulator::TagLib.unify_types([ lt, rt ])
      end

      def run(context, autovivify = false)
        l = @left.run(context, autovivify)
        r = @right.run(context, autovivify)

        l = [ l ] unless l.is_a?(Array)
        r = [ r ] unless r.is_a?(Array)

        res = []

        l.each do |i|
          r.each do |j|
            # we need to handle multi-methods
            op = Fabulator::TagLib.find_op(i.vtype, self.op)
            if op.nil? || !op[:types].include?(j.vtype.join('')) && i.vtype.join('') != j.vtype.join('')
              ut = Fabulator::TagLib.unify_types([ i.vtype, j.vtype ])
              op = Fabulator::TagLib.find_op(ut, self.op)
            end
            if(op && op[:proc])
              calc = op[:proc].call(context, [ i.to(ut), j.to(ut) ])
            else
              calc = self.calculate(i.to(ut).value,j.to(ut).value)
            end
            calc = [ calc ] unless calc.is_a?(Array)

            rut = self.result_type(ut)
            res = res + calc.collect { |c| c.is_a?(Fabulator::Expr::Node) ? c : context.root.anon_node(c, rut) }
          end
        end
        return res
      end

      def result_type(t)
        t
      end
    end

    class AddExpr < BinExpr
      def op
        :plus
      end

      def calculate(a,b)
        return nil if a.nil? || b.nil?
        a + b
      end
    end

    class SubExpr < BinExpr
      def op
        :minus
      end

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
      def op
        :lt
      end

      def calculate(a,b)
        return nil if a.nil? || b.nil?
        a < b
      end
    end

    class LteExpr < BoolBinExpr
      def op
        :lte
      end

      def calculate(a,b)
        return nil if a.nil? || b.nil?
        a <= b
      end
    end

    class EqExpr < BoolBinExpr
      def op
        :eq
      end

      def calculate(a,b)
        a == b
      end
    end

    class NeqExpr < BoolBinExpr
      def op
        :neq
      end

      def calculate(a,b)
        a != b
      end
    end

    class AndExpr < BoolBinExpr
      def op
        :and
      end

      def calculate(a,b)
        a && b
      end
    end

    class OrExpr < BoolBinExpr
      def op
        :or
      end

      def calculate(a,b)
        a || b
      end
    end

    class MpyExpr < BinExpr
      def op
        :times
      end

      def calculate(a,b)
        return nil if a.nil? || b.nil?
        a * b
      end
    end

    class DivExpr < BinExpr
      def op
        :div
      end

      def calculate(a,b)
        return nil if b.nil? || a.nil?
        a / b
      end
    end

    class ModExpr < BinExpr
      def op
        :mod
      end

      def calculate(a,b)
        return nil if a.nil? || b.nil?
        a % b
      end
    end

    class RangeExpr < BinExpr
      def op
        :range
      end

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
