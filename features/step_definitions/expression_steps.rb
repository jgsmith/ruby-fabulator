require 'yaml'

Transform /^(expression|context) \((.*)\)$/ do |n, arg|
  @namespaces ||= { }
  @parser ||= Fabulator::XSM::ExpressionParser.new
  @parser.parse(arg, @namespaces)
end

Transform /^\[(.*)\]$/ do |arg|
  @namespaces ||= { }
  @parser ||= Fabulator::XSM::ExpressionParser.new
  @parser.parse(arg, @namespaces)
end

Transform /^(\d+)$/ do |arg|
  arg.to_i
end

Given 'a context' do
  @roots = { }
  @namespaces = { }
  @data = Fabulator::XSM::Context.new('data', @roots, nil, [])
  @roots['data'] = @data
  @parser ||= Fabulator::XSM::ExpressionParser.new
end

Given /the prefix (\S+) as "([^"]+)"/ do |p,h|
  @namespaces[p] = h
end

Given /that (\[.*\]) is set to (\[.*\])/ do |l,r|
  c = Fabulator::Core::Actions::Value.new
  c.select = r
  c.name = l

  c.run(@data, true)
end

When /I run the (expression \(.*\)) in the (context \(.*\))/ do |exp, cp|
  @expr = exp
  if cp.nil? || cp == ''
    @result = []
    @cp = @data
  else
    @cp = cp.run(@data).first || @data
    @result = @expr.run(@cp)
  end
end

When /I run the (expression \(.*\))/ do |exp|
  ## assume '/' as the context here
  @expr = exp
  @cp = @data
  #puts YAML::dump(@expr)
  @result = @expr.run(@data)
end

Then /I should get (\d+) items?/ do |count|
  @result.length.should == count
end

Then /item (\d+) should be (\[.*\])/ do |i,t|
  test = t.run(@cp).first.value
  @result[i.to_i].value.to_s.should == test.to_s
end

Then /item (\d+) should be false/ do |i|
  (!!@result[i.to_i].value).should == false
end

Then /item (\d+) should be true/ do |i|
  (!!@result[i.to_i].value).should == true
end
