module Fabulator
  module Expr
    class Function
      def initialize(ns_map, nom, args)
        bits = nom.split(/:/, 2)
        @ns = ns_map[bits[0]]
        @name = bits[1]
        @args = args
        @ns_map = ns_map
      end

      def expr_type(context)
        klass = ActionLib.namespaces[@ns]
        rt = klass.function_return_type(@name)
        puts "expr_type for #{@name} => #{(rt[1] rescue 'nil')}"
        rt
      end

      def run(context, autovivify = false)
        klass = ActionLib.namespaces[@ns]
        return [] if klass.nil?
        return klass.run_function(
          context, @ns_map, @name, @args.run(context)
        )
      end
    end

    class List
      def initialize(args)
        @args = args
      end

      def run(context, autovivify = false)
        @args.collect{ |arg| arg.run(context,autovivify).flatten }
      end
    end
  end
end
