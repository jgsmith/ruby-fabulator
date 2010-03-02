module Fabulator
  module Expr
    class AxisChild
      def initialize(n)
        @node_test = n
      end

      def run(context, autovivify = false)
        c = context
        if @node_test.is_a?(String)
          n = @node_test
        else
          n = (@node_test.run(context).last.value rescue nil)
        end
        return [ ] if n.nil?
        if n == '*'
          possible = c.children
        else
          possible = c.children.select{ |cc| cc.name == n }
          if possible.empty? && autovivify
            possible = c.traverse_path([ n ], true)
          end
        end
        return possible
      end
    end

    class AxisDescendentOrSelf
      def initialize(step = nil)
        @step = step
      end

      def run(context, autovivify = false)
        if context.is_a?(Array)
          stack = context
        else
          stack = [ context ]
        end
        possible = [ ]
        while !stack.empty?
          c = stack.shift

          stack = stack + c.children

          possible = possible + c.run(@step, autovivify)
        end
        return possible.uniq
      end
    end

    class AxisParent
      def run(context, autovivify = false)
        if context.is_a?(Array)
          context.collect { |c| c.parent }.uniq
        else
          context.parent
        end
      end
    end

    class AxisAttribute
      def initialize(n)
        @name = n
      end

      def run(context, autovivify = false)
        res = [ ]
        context = [ context ] unless context.is_a?(Array)
        if @name == 'type'
          res = context.collect { |c|
            if c.vtype.nil?
              nil
            else
              n = c.anon_node(nil)
              n.parent = c
              n.set_attribute('namespace', c.vtype[0])
              n.set_attribute('name', c.vtype[1])
              n.name = 'type'
              n.vtype = [ FAB_NS, 'uri' ]
              n
            end
          }
        else
          res = context.collect { |c|
            c.get_attribute(@name)
          }
        end
        res - [ nil ]
      end
    end
  end
end
