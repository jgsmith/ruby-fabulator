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
          n = (@node_test.run(context).last.to_s rescue nil)
        end
        return [ ] if n.nil?
        if n == '*'
          possible = context.is_a?(Array) ? context.collect{|c| c.children}.flatten : context.children
        else
          possible = context.is_a?(Array) ? context.collect{|c| c.children(n)}.flatten : context.children(n)
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

          possible = possible + @step.run(c, autovivify)
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
          
        res = context.collect { |c|
          if @name.is_a?(String)
            nom = @name
          else
            nom = (@name.run(c).last.to_s rescue nil)
          end
          if nom == 'type'
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
          else
            t = c.get_attribute(nom)
            if(t.nil? && autovivify)
              c.set_attribute(nom, nil)
              t = c.get_attribute(nom)
            end
            t
          end
        }
        res = res - [ nil ]
      end
    end
  end
end
