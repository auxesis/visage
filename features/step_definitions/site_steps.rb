Then /^I should see a list of available hosts$/ do
  doc = Nokogiri::HTML(response_body)
  doc.search('div#hosts li').size.should > 0
end
