Then /^I should receive valid JSON$/ do
  yajl = Yajl::Parser.new
  lambda {
    @response = yajl.parse(response_body)
  }.should_not raise_error

  if @response.keys.first == "hosts"
    @response["hosts"].should respond_to(:size)
  else
    host   = @response.keys.first
    plugin = @response[host].keys.first
    metric = @response[host][plugin].keys.first

    host.should_not be_nil
    plugin.should_not be_nil
    metric.should_not be_nil

    data = @response[host][plugin][metric]["data"]
  end

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
  data.values.map { |k,v| k.values }.map {|k,v| k.values }.map {|k,v| k.values }.map do |a|
    a.each do |b|
      string = b["color"]
      string.should =~ /^#[0-9a-fA-F]+$/
      @colours << string
    end
  end

  @colours.uniq.size.should == @colours.size

end

Then /^the plugin instance should have a color$/ do
  Then "each plugin instance should have a different color"
end


Given /^I have the "([^\"]*)" plugin collecting data on multiple ports$/ do |plugin|
  Dir.glob("/var/lib/collectd/rrd/theodor/tcpconns*").size.should > 1
end

Then /^I should see multiple plugins$/ do
  @response.should_not be_nil
  host = @response.keys.first
  @response[host].keys.size.should > 1
end

Then /^I should see multiple hosts$/ do
  @response.should_not be_nil
  @response.keys.size.should > 1
end

Then /^the JSON should have a list of hosts$/ do
  @response["hosts"].size.should > 0
end

Given /^a list of hosts exist$/ do
  When 'I go to /data'
  Then 'the request should succeed'
  Then 'I should receive valid JSON'
  Then 'the JSON should have a list of hosts'
end

When /^I visit "([^"]*)" on the first available host$/ do |glob|
  host = @response["hosts"].first
  url  = "/data/#{host}/#{glob}"
  When "I go to #{url}"
end
