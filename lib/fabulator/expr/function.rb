module Fabulator
  module Expr
    class Function
      def initialize(ctx, nom, args)
        nom.gsub(/\s+/, '')
        bits = nom.split(/:/, 2)
        @ns = ctx.get_ns(bits[0])
        @name = bits[1]
        if @name =~ /^(.+)\*$/
          @name = "consolidation:#{$1}"
        end
        @args = args
        @ctx = ctx
      end

      def expr_type(context)
        return [ FAB_NS, 'boolean' ] if @name =~ /\?$/
        klass = TagLib.namespaces[@ns]
        (klass.function_return_type(@name) rescue nil)
      end

      def run(context, autovivify = false)
        klass = TagLib.namespaces[@ns]
        return [] if klass.nil?
        ctx = @ctx.merge(context)
        ret = klass.run_function(
          ctx, @name, @args.run(ctx)
        )
        if @name =~ /\?$/
          ret = ret.collect{ |v| v.to([FAB_NS, 'boolean']) }
        end
        ret
      end
    end

    class List
      def initialize(args)
        @args = args
      end

      def run(context, autovivify = false)
        @args.collect{ |arg| arg.run(context, autovivify).flatten }
      end
    end

    class Tuple
      def initialize(args)
        @args = args
      end

      def run(context, autovivify = false)
        items = @args.collect{ |arg| arg.run(context, autovivify).flatten }.flatten
        ret = context.root.anon_node(nil, [ FAB_NS, 'tuple' ])
        ret.value = items
        ret.vtype = [ FAB_NS, 'tuple' ]
        ret.set_attribute('size', items.size)
        [ ret ]
      end
    end
  end
end
