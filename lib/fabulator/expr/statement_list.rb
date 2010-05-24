module Fabulator
  module Expr
    class StatementList
      def initialize
        @statements = [ ]
        @ensures = [ ]
        @catches = [ ]
      end

      def add_statement(s)
        @statements << s if !s.nil?
      end

      def add_ensure(s)
        @ensures << s
      end

      def add_catch(s)
        @catches << s
      end

      def is_noop?
        @statements.empty? && @ensures.empty?
      end

      def run(context, autovivify = false)
        result = [ ]
        begin
          (@statements - [nil]).each do |s| 
            result = s.run(context, autovivify)
          end
        rescue Fabulator::StateChangeException => e
          raise e
        rescue => e
          result = []
          caught = false
          ex = nil
          if e.is_a?(Fabulator::Expr::Exception) 
            ex = e.node
          else
            ex = context.anon_node(e.to_s, [ FAB_NS, 'string' ])
            ex.set_attribute('class', 'ruby.' + e.class.to_s.gsub(/::/, '.'))
          end
          @catches.each do |s|
            if !s.nil? && s.run_test(ex)
              caught = true
              result = s.run(ex, autovivify)
            end
          end

          raise e unless caught
        ensure
          @ensures.each do |s|
            s.run(context, autovivify) unless s.nil?
          end
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

