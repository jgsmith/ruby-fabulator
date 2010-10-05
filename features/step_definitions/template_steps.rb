Given /^the template$/ do |doc_xml|
  @template_text = doc_xml
end

When /^I render the template$/ do
  parser = Fabulator::Template::Parser.new
  @template_result = parser.parse(@context, @template_text)
  #puts @template_result.to_s
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
  r = @template_result.to_s
 
  cmd = 'xmllint --c14n --nsclean -'
  IO.popen(cmd, "r+") { |x|
    x << r
    x.close_write
    r = x.readlines.join("")
  }
  IO.popen(cmd, "r+") { |x|
    x << doc
    x.close_write
    doc = x.readlines.join("")
  }

  #@template_result.to_s.should == doc + "\n"
  r = r.gsub(/xmlns(:\S+)?=['"][^'"]*['"]/, '').gsub(/\s+/, ' ').gsub(/\s+>/, '>').gsub(/>\s*</, ">\n<")
  doc = doc.gsub(/xmlns(:\S+)?=['"][^'"]*['"]/, '').gsub(/\s+/, ' ').gsub(/\s+>/, '>').gsub(/>\s*</, ">\n<")
  r.should == doc
end

Then /^the rendered html should equal$/ do |doc|
  r = @template_result.to_html

  cmd = 'xmllint --html --c14n --nsclean -'
  IO.popen(cmd, "r+") { |x|
    x << r
    x.close_write
    r = x.readlines.join("")
  }
  IO.popen(cmd, "r+") { |x|
    x << doc
    x.close_write
    doc = x.readlines.join("")
  }

  #puts "html from template: #{r}"
  #puts "html from doc     : #{doc}"
  r = r.gsub(/xmlns(:\S+)?=['"][^'"]*['"]/, '').gsub(/\s+/, ' ').gsub(/\s+>/, '>').gsub(/>\s*</, ">\n<")
  doc = doc.gsub(/xmlns(:\S+)?=['"][^'"]*['"]/, '').gsub(/\s+/, ' ').gsub(/\s+>/, '>').gsub(/>\s*</, ">\n<")


  r.should == doc
end
