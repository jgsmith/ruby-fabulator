require 'fabulator/expr/context'
require 'fabulator/expr/axis_descendent_or_self'
require 'fabulator/expr/axis'
require 'fabulator/expr/bin_expr'
require 'fabulator/expr/node_logic'
require 'fabulator/expr/node'
require 'fabulator/expr/parser'
require 'fabulator/expr/path_expr'
require 'fabulator/expr/step'
require 'fabulator/expr/unary_expr'
require 'fabulator/expr/union_expr'
require 'fabulator/expr/literal'

require 'fabulator/expr/for_expr'
require 'fabulator/expr/function'
require 'fabulator/expr/if_expr'
require 'fabulator/expr/let_expr'
require 'fabulator/expr/path_expr'
require 'fabulator/expr/predicates'
require 'fabulator/expr/step'

require 'fabulator/expr/statement_list'

module Fabulator
  module Expr
    class ParserError < StandardError
    end

    class Exception < StandardError
      attr_accessor :node

      def initialize(n)
        @node = n
      end
    end
  end
end
