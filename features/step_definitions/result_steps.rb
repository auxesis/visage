Then /^I should see "(.*)"$/ do |text|
  page.body.to_s.should =~ /#{text}/m
end

Then /^I should not see "(.*)"$/ do |text|
  page.body.to_s.should_not =~ /#{text}/m
end

Then /^I should see an? (\w+) message$/ do |message_type|
  response.should have_xpath("//*[@class='#{message_type}']")
end

Then /^the (.*) ?request should succeed/ do |_|
  page.status_code.should < 400
end

Then /^the (.*) ?request should fail/ do |_|
  page.status_code.should >= 400
end
