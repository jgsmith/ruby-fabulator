
Given 'a context' do
  @roots = { }
  @data = Fabulator::XSM::Context.new('data', @roots, nil, [])
  @roots['data'] = @data
  @parser ||= Fabulator::XSM::ExpressionParser.new
end

Given /the path (.*) is set to (.*)/ do |p,v|
  l = @parser.parse(p)
  r = @parser.parse(v)

  c = Fabulator::Core::Value.new
  c.select = r
  c.name = l

  c.run(@data, true)
end

Given /the expression \((.*)\)/ do |exp|
  @expr = @parser.parse(exp)
end

When /I run the expression with the context (.*)/ do |p|
  cp = @parser.parse(p)
  if cp.nil?
    @result = []
  else
    @result = @expr.run(cp.run(@data))
  end
end

Then /I should get (\d+) items?/ do |count|
  @result.length.should_be count
end
