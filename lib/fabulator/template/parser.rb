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
      r = @parser.parse(text)
      (Fabulator::Template::ParseResult.new(r) rescue r)
    end
  end
end
