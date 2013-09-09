When /^I visit the first recent profile$/ do
  visit "/profiles"

  doc     = Nokogiri::HTML(page.body)
  profile = doc.search('div#recent_profiles ul a').first
  profile.should_not be_nil
  href    = profile['href']

  visit(href)
end

Then /^I should see a list of graphs$/ do
  begin
    follow_redirect!
  rescue Rack::Test::Error
  end
  doc = Nokogiri::HTML(page.body)
  doc.search('div#profile div.graph').size.should > 0
end

Then /^I should see a collection of graphs$/ do
  script = <<-SCRIPT
    $$('div#graphs li.graph').length
  SCRIPT

  result = page.evaluate_script(script)
  result.should > 0
end

Then /^I should see a list of profiles$/ do
  doc = Nokogiri::HTML(page.body)
  doc.search('div#profiles ul li').size.should > 1
end

Then /^I should see a list of profiles sorted alphabetically$/ do
  doc = Nokogiri::HTML(page.body)
  profiles = doc.search('div#named_profiles ul li')
  profiles.size.should > 1

  unsorted = profiles.map { |p| p.text.strip }
  sorted = profiles.map { |p| p.text.strip }.sort

  unsorted.should == sorted
end

Then /^I should see a list of recently shared profiles$/ do
  doc = Nokogiri::HTML(page.body)
  profiles = doc.search('div#recent_profiles ul li')
  profiles.size.should > 1
end

Then /^I should see a profile heading$/ do
  doc = Nokogiri::HTML(page.body)
  doc.search('div#profile h2#name').size.should == 1
end

Then /^show me the page source$/ do
  puts page.body
end
