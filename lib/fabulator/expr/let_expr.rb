module Fabulator
  module Expr
    class LetExpr
      def initialize(dqname, expr)
        @expr = expr
        dqname =~ /^\$?(.*)$/
        @name = $1
      end

      def run(context, autovivify = false)
        result = @expr.run(context, autovivify)
        context.set_var(@name, result)
        return [ ]
      end
    end

#    class Var
#      def initialize(dqname)
#        dqname =~ /^\$?(.*)$/
#        @name = $1
#      end
#
#      def run(context, autovivify = false)
#        r = context.get_var(@name)
#        return r.is_a?(Array) ? r : [ r ]
#      end
#    end
  end
end
