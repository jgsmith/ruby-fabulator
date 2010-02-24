Given /the statemachine/ do |doc_xml|
  doc = LibXML::XML::Document.string doc_xml

  @roots = { }
  @namespaces = { }
  @data = Fabulator::Expr::Context.new('data', @roots, nil, [])
  @roots['data'] = @data
  @parser ||= Fabulator::Expr::Parser.new
  @sm = Fabulator::Core::StateMachine.new.compile_xml(doc)
  @sm.init_context(@data)
end

When /I run it with the following params:/ do |param_table|
  params = { }
  param_table.hashes.each do |hash|
    params[hash['key']] = hash['value']
  end
  @sm.run(params)
end

Then /it should be in the '(.*)' state/ do |s|
  @sm.state.should == s
end
