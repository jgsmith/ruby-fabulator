module Fabulator
  class TagLib
    class Presentations
      def initialize
        @transformations = Fabulator::TagLib::Transformations.new
        @interactives = { }
        @structurals = { }
      end

      def transformations_into
        @transformations
      end

      def interactives
        @interactives.keys
      end

      def structurals
        @structurals.keys
      end

      def interactive(nom)
        @interactives[nom.to_sym] = nil
      end

      def structural(nom)
        @structurals[nom.to_sym] = nil
      end

      def transform(fmt, doc, opts = { })
        @transformations.transform(fmt, doc, opts)
      end
    end
  end
end
