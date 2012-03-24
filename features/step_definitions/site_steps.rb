When /^I visit the first profile$/ do
  doc = Nokogiri::HTML(response_body)
  link_text = doc.search('div#profiles ul a').first['href']

  visit(link_text)
end

Then /^I should see a list of graphs$/ do
  begin
    follow_redirect!
  rescue Rack::Test::Error
  end

  doc = Nokogiri::HTML(response_body)
  doc.search('div#profile div.graph').size.should > 0
end

Then /^I should see a list of profiles$/ do
  doc = Nokogiri::HTML(response_body)
  doc.search('div#profiles ul li').size.should > 1
end

Then /^I should see a list of profiles sorted alphabetically$/ do
  doc = Nokogiri::HTML(response_body)
  profiles = doc.search('div#profiles ul li')
  profiles.size.should > 1

  unsorted = profiles.map { |p| p.text.strip }
  sorted = profiles.map { |p| p.text.strip }.sort

  unsorted.should == sorted
end

Then /^I should see a profile heading$/ do
  doc = Nokogiri::HTML(response_body)
  doc.search('div#profile h2#name').size.should == 1
end

Then /^show me the page source$/ do
  puts response_body
end
