module Fabulator
  module Expr
    class PathExpr
      def initialize(pe, predicates, segment)
        @primary_expr = pe
        @predicates = predicates
        @segment = (segment.is_a?(Array) ? segment : [ segment ]) - [nil]
      end

      def run(context, autovivify = false)
        if @primary_expr.nil?
          possible = [ context ]
        else
          begin
            possible = @primary_expr.run(context,autovivify).uniq
          rescue
            possible = [ context ]
          end
        end

        final = [ ]

        @segment = [ @segment ] unless @segment.is_a?(Array)

        possible.each do |e|
          next if e.nil?
          not_pass = false
          @predicates.each do |p|
            if !p.test(e)
              not_pass = true
              break
            end
          end
          next if not_pass
          pos = [ e ]
          @segment.each do |s|
            pos = pos.collect{ |p| s.run(p, autovivify) }.flatten
          end
            
          final = final + pos
        end

        return final
      end
    end
  end
end