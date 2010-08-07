module Fabulator::Template
  class Parser
    include Fabulator::Template::Taggable
    include Fabulator::Template::StandardTags

    def parse(context, text)
      if !@context
        @context = Context.new(self)
      end
      if !@parser
        @parser = Radius::Parser.new(@context, :tag_prefix => 'r')
      end
      @context.globals.context = context
      Fabulator::Template::ParseResult.new(@parser.parse(text))
    end
  end
end
