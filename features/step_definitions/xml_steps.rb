Given /the statemachine/ do |doc_xml|
  doc = LibXML::XML::Document.string doc_xml

  @roots ||= { }
  @namespaces ||= { }
  @data ||= Fabulator::Expr::Node.new('data', @roots, nil, [])
  @roots['data'] ||= @data
  @context ||= Fabulator::Expr::Context.new
  @context.root = @data

  @parser ||= Fabulator::Expr::Parser.new
  if @sm.nil?
    @sm = Fabulator::Core::StateMachine.new.compile_xml(doc, @context)
  else
    @sm.compile_xml(doc, @context)
  end
  @sm.init_context(@context)
end

When /I run it with the following params:/ do |param_table|
  params = { }
  param_table.hashes.each do |hash|
    params[hash['key']] = hash['value']
  end
  @sm.run(params)
  #puts YAML::dump(@sm)
end

Then /it should be in the '(.*)' state/ do |s|
  @sm.state.should == s
end
