module Fabulator
  module Lib
    class Function < Fabulator::Structural
      namespace FAB_LIB_NS

      attribute :name, :static => true

      has_actions
    end

    class Mapping < Fabulator::Structural
      namespace FAB_LIB_NS

      attribute :name, :static => true

      has_actions
    end

    class Reduction < Fabulator::Structural
      namespace FAB_LIB_NS

      attribute :name, :static => true

      has_actions
    end

    class Consolidation < Fabulator::Structural
      namespace FAB_LIB_NS

      attribute :name, :static => true

      has_actions
    end
  end
end

