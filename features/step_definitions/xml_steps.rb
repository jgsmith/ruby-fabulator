Given /the statemachine/ do |doc_xml|
  @context ||= Fabulator::Expr::Context.new

  if @sm.nil?
    @sm = Fabulator::Core::StateMachine.new
    @sm.compile_xml(doc_xml)
  else
    @sm.compile_xml(doc_xml)
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
