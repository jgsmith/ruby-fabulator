module Fabulator
  module Expr
    class Literal
      def initialize(e, t = nil)
        @lit = e
        @type = t
      end

      def expr_type(context)
        @type
      end

      def run(context, autovivify = false)
        return [ context.root.anon_node(@lit, @type) ]
      end
    end
    
    class Bag
      def initialize(b)
        @bag = b
      end
      
      def run(context, autovivify = false)
        root = context.root.anon_node(nil)
        ctx = context.with_root(root)
        @bag.each do |setting|
          ctx.set_value(setting.first, setting.last)
        end
        #puts YAML::dump(ctx.root.to_h)
        return [ ctx.root ]
      end
    end

    class Var
      def initialize(v)
        @var = v
      end

      def expr_type(context)
        v = context.get_var(@var)
        if( v.is_a?(Array) )
          TagLib.unify_types(v.collect{ |i| i.vtype })
        else
          v.vtype
        end
      end

      def run(context, autovivify = false)
        v = context.get_var(@var)
        return [] if v.nil?
        return v.is_a?(Array) ? v : [ v ]
      end
    end
  end
end
