module Fabulator
  module Expr
    class Axis
      def initialize(axis, n = nil)
        case axis
          when 'attribute':
            @axis = AxisAttribute.new(n)
          when 'child':
            @axis = AxisChild.new(n)
          when 'child-or-self':
          when 'descendent':
          when 'descendent-or-self':
            @axis = AxisDescendentOrSelf.new(n)
          when 'parent':
            @axis = AxisParent.new(n)
          else
            @root = axis
            @axis = n.nil? ? nil : AxisChild.new(n)
        end
      end

      def run(context, autovivify = false)
        if @root.nil? || @root == ''
          return @axis.run(context, autovivify)
        else
          if context.roots[@root].nil? && !Fabulator::ActionLib.axes[@root].nil?
            context.roots[@root] = Fabulator::ActionLib.axes[@root].call(context)
          end
          return context.roots[@root].nil? ? [ ] : 
                                @axis.nil? ? [ context.roots[@root] ] : 
                                             [ @axis.run(context.roots[@root]) ]
        end
      end
    end

    class AxisChild
      def initialize(n)
        @node_test = n
      end

      def run(context, autovivify = false)
        if @node_test.is_a?(String)
          n = @node_test
        else
          n = (@node_test.run(context).last.value rescue nil)
        end
        return [ ] if n.nil?
        if n == '*'
          possible = context.children
        else
          possible = context.children(n)
          if possible.empty? && autovivify
            possible = context.traverse_path([ n ], true)
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
