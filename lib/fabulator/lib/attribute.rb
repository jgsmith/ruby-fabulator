module Fabulator
  module Lib
    class Attribute < Fabulator::Structural
      namespace FAB_LIB_NS

      attribute :name, :static => true
      attribute :ns, :static => true, :inherited => true
      attribute :static, :static => true, :type => :boolean
      attribute :eval, :static => true, :type => :boolean
      attribute :inherited, :static => true, :type => :boolean

      def is_static?
        @static
      end

      def value(context)
        v = context.attribute(@ns, @name, { :static => @static, :eval => @eval, :inherited => @inherited })
        if @eval || !@static
          v = context.root.anon_node(v, [ FAB_NS, 'expression' ])
        end
        v
      end
    end
  end
end
