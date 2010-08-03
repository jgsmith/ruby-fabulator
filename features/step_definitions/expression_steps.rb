require 'yaml'

Transform /^(expression|context) \((.*)\)$/ do |n, arg|
  @namespaces ||= { }
  @parser ||= Fabulator::Expr::Parser.new
  @parser.parse(arg, @context)
end

Transform /^\[(.*)\]$/ do |arg|
  @parser ||= Fabulator::Expr::Parser.new
  @parser.parse(arg, @context)
end

Transform /^(\d+)$/ do |arg|
  arg.to_i
end

Given 'a context' do
  @roots ||= { }
  @data ||= Fabulator::Expr::Node.new('data', @roots, nil, [])
  @roots['data'] ||= @data
  @context ||= Fabulator::Expr::Context.new
  @context.root = @data
  @parser ||= Fabulator::Expr::Parser.new
end

Given /the prefix (\S+) as "([^"]+)"/ do |p,h|
  @context ||= Fabulator::Expr::Context.new
  @context.set_ns(p, h)
end

Given /that (\[.*\]) is set to (\[.*\])/ do |l,r|
  @context.set_value(l, r)
end

When /I run the (expression \(.*\)) in the (context \(.*\))/ do |exp, cp|
  @expr = exp
  if cp.nil? || cp == ''
    @result = []
    @cp = @context.root
  else
    @cp = cp.run(@context).first || @context.root
    @result = @expr.run(@context.with_root(@cp))
  end
end

When /I run the (expression \(.*\))/ do |exp|
  ## assume '/' as the context here
  @expr = exp
  @cp = @data
  #puts YAML::dump(@expr)
  @result = @expr.run(@context.with_root(@cp))
  #puts YAML::dump(@result)
end

When /I unify the types? (.*)/ do |ts|
  types = ts.split(/\s*,\s*/)
  typea = types.collect { |t|
      pn = t.split(/:/, 2)
      [ @context.get_ns(pn[0]), pn[1] ]
    }
  @type_result = Fabulator::ActionLib.unify_types(
    types.collect { |t|
      pn = t.split(/:/, 2)
      [ @context.get_ns(pn[0]), pn[1] ]
    }
  )
end

Then /I should get the type (.*)/ do |t|
  pn = t.split(/:/, 2)
  @type_result[0].should == @context.get_ns(pn[0])
  @type_result[1].should == pn[1]
end

Then /I should get (\d+) items?/ do |count|
  @result.length.should == count
end

Then /item (\d+) should be (\[.*\])/ do |i,t|
  test = t.run(@context.with_root(@cp)).first
   #puts "Result: #{@result[i.to_i].to_s.class.to_s}"
  @result[i.to_i].to_s.should == test.to_s
end

Then /item (\d+) should be false/ do |i|
  (!!@result[i.to_i].value).should == false
end

Then /item (\d+) should be true/ do |i|
  (!!@result[i.to_i].value).should == true
end

Then /the (expression \(.*\)) should equal (\[.*\])/ do |x, y|
  a = x.run(@context)
  b = y.run(@context)
  #puts YAML::dump(a)
  #puts YAML::dump(b)
  #puts YAML::dump(@context)
  a.first.value.should == b.first.value
end

Then /the (expression \(.*\)) should be nil/ do |x|
  x.run(@context).first.should == nil
end
