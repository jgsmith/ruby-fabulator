module Fabulator
  module Expr
    class Predicates
      def initialize(axis,p)
        @axis = axis
        @predicates = p
      end

      def run(context, autovivify = false)
        # we want to run through all of the predicates and return true if
        # they all return true
        result = [ ]
        possible = @axis.run(context, autovivify)
        return possible if @predicates.nil? || @predicates.empty?
        @predicates.each do |p|
          n_p = [ ]
          if p.is_a?(Fabulator::Expr::IndexPredicate)
            n_p = p.run(context).collect{ |i| possible[i-1] }
          else
            possible.each do |c|
              res = p.run(context.with_root(c))
              if res.is_a?(Array)
                n_p << c if !res.empty? && !!res.first.value
              else
                n_p << c if !!res.value
              end
            end
          end
          possible = n_p
        end
        return possible
      end
    end

    class IndexPredicate
      def initialize(l)
        @indices = l
      end

      def run(context)
        @indices.collect { |e| e.run(context).collect{ |i| i.to([FAB_NS, 'numeric']).value.to_i } }.flatten
      end
    end
  end
end
