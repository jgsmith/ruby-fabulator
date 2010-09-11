module Fabulator
  module Lib
    class Attribute < Fabulator::Structural
      namespace FAB_LIB_NS

      attribute :name, :static => true
      attribute :ns, :static => true, :inherited => true
      attribute :static, :static => true, :type => :boolean
      attribute :eval, :static => true, :type => :boolean

      def is_static?
        @static
      end

      def value(context)
        context.attribute(@ns, @name, { :static => @static, :eval => @eval })
      end
    end
  end
end
