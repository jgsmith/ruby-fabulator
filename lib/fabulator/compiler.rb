require 'xml/libxml'

module Fabulator
  class Compiler
    def initialize
      @context = Fabulator::Expr::Context.new
    end

    # Calls the right compiler object based on the root element
    def compile(xml)
      XML.default_line_numbers = true

      doc = nil

      if xml.is_a?(String)
        doc = LibXML::XML::Document.string xml
        doc = doc.root
      elsif xml.is_a?(LibXML::XML::Document)
        doc = xml.root
      else
        doc = xml
      end

      @context.compile_structural(doc)
    end
  end
end
