module Fabulator
  module Expr
    class Literal
      def initialize(e, t = nil)
        @lit = e
        @type = t
      end

      def expr_type(context)
        @type
      end

      def run(context, autovivify = false)
        return [ context.anon_node(@lit, @type) ]
      end
    end

    class Var
      def initialize(v)
        @var = v
      end

      def expr_type(context)
        v = context.get_var(@var)
        if( v.is_a?(Array) )
          ActionLib.unify_types(v.collect{ |i| i.vtype })
        else
          v.vtype
        end
      end

      def run(context, autovivify = false)
        v = context.get_var(@var)
        return [] if v.nil?
        return v.is_a?(Array) ? v : [ v ]
      end
    end
  end
end
