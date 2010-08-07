require 'radius'

module Fabulator::Template
  class Context < Radius::Context

  attr_reader :context

  def initialize(page)
    super()
    @page = page
    globals.context = @context
    page.tags.each do |name|
      define_tag(name) { |tag_binding| page.render_tag(name, tag_binding) }
    end
  end

  def raise_errors?
    true
  end

  def render_tag(name, attributes = {}, &block)
    binding = @tag_binding_stack.last
    locals = binding ? binding.locals : globals
    set_process_variables(locals.page)
    super
  rescue Exception => e
    raise e if raise_errors?
    @tag_binding_stack.pop unless @tag_binding_stack.last == binding
    render_error_message(e.message)
  end

  def tag_missing(name, attributes = {}, &block)
    super
  rescue Radius::UndefinedTagError => e
    raise StandardTags::TagError.new(e.message)
  end

  private

    def render_error_message(message)
      "<div><strong>#{message}</strong></div>"
    end

    def set_process_variables(page)
      #page.request ||= @page.request
      #page.response ||= @page.response
    end

  end
end

