Then /^I should receive valid JSON$/ do
  yajl = Yajl::Parser.new
  lambda {
    yajl.parse(response_body)
  }.should_not raise_error
end
