module Fabulator
  module Expr
    class ForExpr
      def initialize(v, e)
        if v.size > 1
          @var = v.shift
          @expr = Fabulator::Expr::ForExpr.new(v, e)
        else
          @var = v.first
          @expr = e
        end
      end

      def expr_type(context)
        @expr.expr_type(context)
      end

      def run(context, autovivify = false)
        result = [ ]
        return result if @var.nil? || @expr.nil?

        @var.each_binding(context, autovivify) do |b|
          result = result + @expr.run(b)
        end
        return result
      end
    end

    class EveryExpr < ForExpr
      def expr_type(context)
        [ FAB_NS, 'boolean' ]
      end

      def run(context, autovivify = false)
        result = super
        result.each do |r|
          return [ context.anon_node(false) ] unless !!r.value
        end
        return [ context.anon_node(true) ]
      end
    end

    class SomeExpr < ForExpr
      def expr_type(context)
        [ FAB_NS, 'boolean' ]
      end

      def run(context, autovivify = false)
        result = super
        result.each do |r|
          return [ context.anon_node(true) ] if !!r.value
        end
        return [ context.anon_node(false) ]
      end
    end

    class ForVar
      def initialize(n, e)
        n =~ /^\$?(.*)$/
        @var_name = $1
        @expr = e
      end

      def each_binding(context, autovivify = false, &block)
        context.in_context do
          @expr.run(context, autovivify).each do |e|
            #context.in_context do
              context.set_var(@var_name, e)
              yield context
            #end
          end
        end
      end
    end
  end
end
