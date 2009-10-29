Then /^I should receive valid JSON$/ do
  yajl = Yajl::Parser.new
  lambda {
    yajl.parse(response_body)
  }.should_not raise_error
end

Then /^I should receive JSON wrapped in a callback named "([^\"]*)"$/ do |callback|
  response_body.should =~ /^#{callback}\(.+\)$/
end

Then /^the JSON should have a plugin instance named "([^\"]*)"$/ do |plugin_instance|
  yajl = Yajl::Parser.new
  data = yajl.parse(response_body)

  data.values.map { |k,v| k.values }.map {|k,v| k.keys }.flatten.include?(plugin_instance).should be_true
end

Then /^the JSON should have a plugin named "([^\"]*)"$/ do |plugin|
  yajl = Yajl::Parser.new
  data = yajl.parse(response_body)

  data.values.map { |k,v| k.keys }.flatten.include?(plugin).should be_true
end

Then /^the JSON should have multiple plugin instances under the "([^\"]*)" plugin$/ do |arg1|
  yajl = Yajl::Parser.new
  data = yajl.parse(response_body)

  data.values.map { |k,v| k[arg1] }.map { |k,v| k.keys }.flatten.size.should > 1
end

Then /^each plugin instance should have a different color$/ do
  yajl = Yajl::Parser.new
  data = yajl.parse(response_body)

  @colours = []
  data.values.map { |k,v| k.values }.map {|k,v| k.values }.map do |a|
    a.each do |b|
      b.last.should =~ /^#[0-9a-fA-F]+$/
      @colours << b.last
    end
  end

  @colours.uniq.size.should == @colours.size

end

Then /^the plugin instance should have a color$/ do
  Then "each plugin instance should have a different color"
end

