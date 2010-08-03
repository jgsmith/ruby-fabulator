module Fabulator
  module Expr
    class PathExpr
      def initialize(pe, predicates, segment)
        @primary_expr = pe
        @predicates = predicates
        @segment = (segment.is_a?(Array) ? segment : [ segment ]) - [nil]
      end

      def expr_type(context)
        nil
      end

      def run(context, autovivify = false)
        if @primary_expr.nil?
          possible = [ context.root ]
        else
          possible = @primary_expr.run(context,autovivify).uniq
        end

        final = [ ]

        @segment = [ @segment ] unless @segment.is_a?(Array)

        possible.each do |e|
          next if e.nil?
          not_pass = false
          @predicates.each do |p|
            if !p.test(context.with_root(e))
              not_pass = true
              break
            end
          end
          next if not_pass
          pos = [ e ]
          @segment.each do |s|
            pos = pos.collect{ |p| 
              s.run(context.with_root(p), autovivify) 
            }.flatten - [ nil ]
          end
            
          final = final + pos
        end

         #puts "path_expr returning #{YAML::dump(final)}"
        return final
      end
    end
  end
end
