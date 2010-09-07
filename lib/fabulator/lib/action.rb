module Fabulator
  module Lib
    class Action < Fabulator::Structural
      namespace FAB_LIB_NS

      attribute :name, :static => true

      contains :attribute

      has_actions
    end
  end
end
