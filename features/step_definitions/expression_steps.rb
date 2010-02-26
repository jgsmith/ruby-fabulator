require 'yaml'

Transform /^(expression|context) \((.*)\)$/ do |n, arg|
  @namespaces ||= { }
  @parser ||= Fabulator::Expr::Parser.new
  @parser.parse(arg, @namespaces)
end

Transform /^\[(.*)\]$/ do |arg|
  @namespaces ||= { }
  @parser ||= Fabulator::Expr::Parser.new
  @parser.parse(arg, @namespaces)
end

Transform /^(\d+)$/ do |arg|
  arg.to_i
end

Given 'a context' do
  @roots = { }
  @namespaces = { }
  @data = Fabulator::Expr::Context.new('data', @roots, nil, [])
  @roots['data'] = @data
  @parser ||= Fabulator::Expr::Parser.new
end

Given /the prefix (\S+) as "([^"]+)"/ do |p,h|
  @namespaces ||= { }
  @namespaces[p] = h
end

Given /that (\[.*\]) is set to (\[.*\])/ do |l,r|
  @data.set_value(l, r)
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

When /I unify the types? (.*)/ do |ts|
  types = ts.split(/\s*,\s*/)
  typea = types.collect { |t|
      pn = t.split(/:/, 2)
      [ @namespaces[pn[0]], pn[1] ]
    }
  @type_result = Fabulator::ActionLib.unify_types(
    types.collect { |t|
      pn = t.split(/:/, 2)
      [ @namespaces[pn[0]], pn[1] ]
    }
  )
end

Then /I should get the type (.*)/ do |t|
  pn = t.split(/:/, 2)
  @type_result[0].should == @namespaces[pn[0]]
  @type_result[1].should == pn[1]
end

Then /I should get (\d+) items?/ do |count|
  @result.length.should == count
end

Then /item (\d+) should be (\[.*\])/ do |i,t|
  test = t.run(@cp).first.to_s
  @result[i.to_i].value.to_s.should == test
end

Then /item (\d+) should be false/ do |i|
  (!!@result[i.to_i].value).should == false
end

Then /item (\d+) should be true/ do |i|
  (!!@result[i.to_i].value).should == true
end

Then /the (expression \(.*\)) should equal (\[.*\])/ do |x, y|
  x.run(@data).first.value.should == y.run(@data).first.value
end

Then /the (expression \(.*\)) should be nil/ do |x|
  x.run(@data).first.should == nil
end
