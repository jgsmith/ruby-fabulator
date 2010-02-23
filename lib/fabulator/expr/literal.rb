module Fabulator
  module Expr
    class Literal
      def initialize(e, t)
        @lit = e
        @type = t
      end

      def run(context, autovivify = false)
        return [ context.anon_node(@lit, @type) ]
      end
    end

    class Var
      def initialize(v)
        @var = v
      end

      def run(context, autovivify = false)
        v = context.get_var(@var)
        return [] if v.nil?
        return v.is_a?(Array) ? v : [ v ]
      end
    end
  end
end