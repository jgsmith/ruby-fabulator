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
  end
end

