module Fabulator
  module Expr
    class StatementList
      def initialize
        @statements = [ ]
      end

      def add_statement(s)
        @statements << s if !s.nil?
      end

      def run(context, autovivify = false)
        result = [ ]
        (@statements - [nil]).each do |s| 
          result = s.run(context, autovivify)
        end
        return result
      end
    end

    class WithExpr
      def initialize(e,w)
        @expr = e
        @with = w
      end

      def run(context, autovivify = false)
        result = @expr.run(context, autovivify)
        result.each do |r|
          @with.run(r, true)
        end
        result
      end
    end

    class DataSet
      def initialize(p,v)
        @path = p
        @value = v
      end

      def run(context, autovivify = false)
        context.set_value(@path, @value)
        [ context ]
      end
    end
  end
end

