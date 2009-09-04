Then /^I should receive valid JSON$/ do
  yajl = Yajl::Parser.new
  lambda {
    yajl.parse(response_body)
  }.should_not raise_error
end

Then /^I should receive JSON wrapped in a callback named "([^\"]*)"$/ do |callback|
  response_body.should =~ /^#{callback}\(.+\)$/
end

Then /^the JSON should have a plugin instance named "([^\"]*)"$/ do |arg1|
  pending
end

Then /^the JSON should have a plugin named "([^\"]*)"$/ do |arg1|
  pending
end

Then /^the JSON should have multiple plugin instances under the "([^\"]*)" plugin$/ do |arg1|
  pending
end

