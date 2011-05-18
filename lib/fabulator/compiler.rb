require 'nokogiri'

module Fabulator
  class Compiler
    def initialize
      @context = Fabulator::Expr::Context.new
    end

    # Calls the right compiler object based on the root element
    def compile(xml)
      doc = nil

      if xml.is_a?(String)
        doc = Nokogiri::XML::Document.parse(xml, nil, nil,
                Nokogiri::XML::ParseOptions::STRICT
                |Nokogiri::XML::ParseOptions::PEDANTIC
                |Nokogiri::XML::ParseOptions::NONET
              )
        doc = doc.root
      elsif xml.is_a?(Nokogiri::XML::Document)
        doc = xml.root
      else
        doc = xml
      end

      @context.compile_structural(doc)
    end
  end
end
