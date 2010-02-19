Given 'a context' do
  @roots = { }
  @data = Fabulator::XSM::Context.new('data', @roots, nil, [])
  @roots['data'] = @data
  @parser ||= Fabulator::XSM::ExpressionParser.new
end

Given /that (.*) is set to (.*)/ do |p,v|
  l = @parser.parse(p)
  r = @parser.parse(v)

  c = Fabulator::Core::Actions::Value.new
  c.select = r
  c.name = l

  c.run(@data, true)
end

When /I run the expression \((.*)\) in the context (.*)/ do |exp, p|
  @expr = @parser.parse(exp)
  cp = @parser.parse(p)
  if cp.nil?
    @result = []
  else
    @result = @expr.run(cp.run(@data).first || @data)
  end
end

Then /I should get (\d+) items?/ do |count|
  @result.length.should equal count.to_i
end

Then /item (\d+) should be \[(.*)\]/ do |i,t|
  @result[i.to_i].value.to_s.should eql t.to_s
end
