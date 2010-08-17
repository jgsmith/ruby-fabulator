Given /^the template$/ do |doc_xml|
  @template_text = doc_xml
end

When /^I render the template$/ do
  parser = Fabulator::Template::Parser.new
  @template_result = parser.parse(@context, @template_text)
  #puts @template_result.to_html unless @template_result.is_a?(String)
end

When /^I set the captions to:$/ do |caption_table|
  captions = { }
  caption_table.hashes.each do |h|
    captions[h['path']] = h['caption']
  end

  @template_result.add_captions(captions)
end

When /^I set the defaults to:$/ do |caption_table|
  captions = { }
  ctx = @context.with_root(@context.root.anon_node(nil))
  caption_table.hashes.each do |h|
    ctx.set_value(h['path'], Fabulator::Expr::Literal.new(h['default']))
  end

  @template_result.add_default_values(ctx)
end

Then /^the rendered text should equal$/ do |doc|
  @template_result.to_s.should == %{<?xml version="1.0" encoding="UTF-8"?>\n} + doc + "\n"
end

Then /^the rendered html should equal$/ do |doc|
  @template_result.to_html.should == doc
end
