When /^I add a graph$/ do
  script = <<-SCRIPT
    // Reset all the checkboxes
    $$('div#hosts input.checkbox').each(function(checkbox) { if (checkbox.checked) { checkbox.click() }})
    // Select a random checkbox
    $$('div#hosts input.checkbox').shuffle()[0].click();
  SCRIPT
  execute_script(script) # so metrics can be fetched

  script = <<-SCRIPT
    $$('div#metrics input.checkbox')[0].click();
    $$('div#display input.button')[0].click();
  SCRIPT
  execute_script(script)
end

When(/^I add (\d+) graphs$/) do |count|
  count = count.to_i
  count.times { step 'I add a graph' }

  script = <<-SCRIPT
    window.graphs.length
  SCRIPT
  page.evaluate_script(script).should == count
end

When /^I share the profile$/ do
  script = <<-SCRIPT
    $('share-toggler').fireEvent('click');
  SCRIPT
  execute_script(script)
end

Then /^I should see a permalink for the profile$/ do
  page.current_path.should_not match(/\/profiles\/new$/)
  page.current_path.should match(/\/profiles\/[0-9a-f]+$/)
end

When(/^I create an anonymous profile$/) do
  step "I go to /profiles/new"
  step "I add a graph"
  step "I share the profile"
  step "I should see a permalink for the profile"
  @anonymous_profile_url = page.current_path
end

When(/^I visit that anonymous profile$/) do
  step "I visit the first recent profile"
  step "I should see a collection of graphs"
end

Then(/^I should see a new permalink for the profile$/) do
  page.current_path.should_not == @anonymous_profile_url
end

When(/^I share the profile with the name "(.*?)"$/) do |name|
  script = <<-SCRIPT
    $('share-toggler').fireEvent('click');
  SCRIPT
  execute_script(script)

  script = <<-SCRIPT
    $('profile-anonymous').checked = true;
    $('profile-anonymous').fireEvent('click');
  SCRIPT
  execute_script(script)

  script = <<-SCRIPT
    $('profile-name').set('value', '#{name}');
    $('share-save').fireEvent('click');
  SCRIPT
  execute_script(script, :wait => 3)
end

Then(/^I should see a profile named "(.*?)"$/) do |name|
  doc = Nokogiri::HTML(page.body)
  profiles = doc.search('div#named_profiles ul li')
  profiles.size.should > 0

  match = profiles.find {|profile| profile.text =~ /#{name}/}
  match.should_not be_nil
end

Then(/^I should not see a profile named "(.*?)"$/) do |name|
  doc = Nokogiri::HTML(page.body)
  profiles = doc.search('div#named_profiles ul li')
  profiles.size.should > 0

  match = profiles.find {|profile| profile.text =~ /#{name}/}
  match.should be_nil
end

When(/^I create a profile named "(.*?)"$/) do |name|
  step %(I go to /profiles/new)
  step %(I add a graph)
  step %(I share the profile with the name "#{name}")
  step %(I should see a permalink for the profile)
  step %(I go to /profiles)
  step %(I should see a profile named "#{name}")
end

When(/^I visit a profile named "(.*?)"$/) do |name|
  step 'I go to /profiles'
  step %(I follow "#{name}")
end

When(/^I activate the share modal$/) do
  step 'I share the profile'
end

When(/^I delete the profile$/) do
  script = <<-SCRIPT
    $('share-delete').fireEvent('click');
  SCRIPT
  execute_script(script, :wait => 3)
end

Then(/^I should be at (.*)$/) do |path|
  page.current_path.should == path
end

Then(/^I should see "(.*?)" in the page title$/) do |name|
  doc = Nokogiri::HTML(page.body)
  title = doc.search('head title')
  title.text.should match(/#{name}/)
end

Then(/^I should not see a permalink for the profile$/) do
  page.current_path.should match(/\/profiles\/new$/)
  page.current_path.should_not match(/\/profiles\/[0-9a-f]+$/)
end

Then(/^I should see a modal prompting me to add graphs$/) do
  script = <<-SCRIPT
    $('errors') == null
  SCRIPT
  page.evaluate_script(script).should be_false

  script = <<-SCRIPT
    $$('div#errors div.error').length
  SCRIPT
  page.evaluate_script(script).should > 0
end

Then(/^I should only see a button to close the dialog$/) do
  script = <<-SCRIPT
    $$('div.lightfaceFooter input.action').length
  SCRIPT
  page.evaluate_script(script).should == 1
end

When(/^I set the timeframe to "(.*?)"$/) do |timeframe|
  script = <<-SCRIPT
    $('timeframe-toggler').fireEvent('click');

    var timeframes = $$('ul#timeframes li.timeframe');
    var match = timeframes.filter(function(item, index) {
      return item.get('html') == '#{timeframe}'
    })[0];
    match.fireEvent('click');
  SCRIPT
  execute_script(script)
end

Then(/^the graphs should have data for the last (\d+) hours*$/) do |hours|
  script = <<-SCRIPT
    window.profile.get('graphs').map(function(graph) { return graph.start })
  SCRIPT
  start_times = page.evaluate_script(script)
  start_times.size.should > 0

  n_hours_ago = (Time.now - (hours.to_i * 3600)).to_i
  start_range = n_hours_ago - 30
  end_range   = n_hours_ago + 30

  # All the start times should be the same
  start_times.uniq.size.should == 1

  offset = Time.now.gmtoff
  start_times.each do |time|
    t = time - offset
    p [offset, start_range, time, t, end_range]
    p start_range == end_range
    time.should be_between(start_range, end_range)
  end
end

Then(/^the graphs should have data for exactly (\d+) hours$/) do |hours|
  hours        = hours.to_i
  seconds      = hours * 60 * 60
  fuzzy_start  = seconds - 30
  fuzzy_finish = seconds + 30

  script = <<-SCRIPT
    window.profile.get('graphs').map(function(graph) { return graph.start })
  SCRIPT
  start_times = page.evaluate_script(script).compact
  start_times.size.should > 0

  script = <<-SCRIPT
    window.profile.get('graphs').map(function(graph) { return graph.finish })
  SCRIPT
  finish_times = page.evaluate_script(script).compact
  finish_times.size.should > 0

  start_times.zip(finish_times).each do |start, finish|
    (finish - start).should be_between(fuzzy_start, fuzzy_finish)
  end
end

When(/^I set the profile name to "(.*?)"$/) do |name|
  script = <<-SCRIPT
    $('profile-anonymous').checked = true;
    $('profile-anonymous').fireEvent('click');
    $('profile-name').set('value', '#{name}');
  SCRIPT
  execute_script(script)
end

When(/^I save the profile$/) do
  script = <<-SCRIPT
    $('share-save').fireEvent('click');
  SCRIPT
  execute_script(script, :wait => 3)
end

When(/^I check the "Remember the timeframe" option$/) do
  pending
end

When(/^I remember the timeframe absolutely$/) do
  script = <<-SCRIPT
    $('profile-timeframe-absolute').checked = true;
    $('profile-timeframe-absolute').fireEvent('click');
  SCRIPT
  execute_script(script)
end

When(/^I remember the timeframe relatively$/) do
  script = <<-SCRIPT
    $('profile-timeframe-relative').checked = true;
    $('profile-timeframe-relative').fireEvent('click');
  SCRIPT
  execute_script(script)
end

When(/^I remember the timeframe when sharing the profile named "(.*?)"$/) do |name|
  step %(I activate the share modal)
  step %(I set the profile name to "#{name}")
  step %(I check the "Remember the timeframe" option)
  step %(I save the profile)
end

When(/^I reset the timeframe$/) do
  step %(I go to /profiles/new)
  step %(I set the timeframe to "last 6 hours")
end

When(/^I go (\d+) minutes into the future$/) do |minutes|
  Delorean.time_travel_to("#{minutes} minutes from now")
end

Then(/^the timeframe should be "(.*?)"$/) do |timeframe|
  script = <<-SCRIPT
    $('timeframe-label').get('html')
  SCRIPT

  page.evaluate_script(script).should == timeframe
end

Then(/^show me the timeframe cookie$/) do
  script = <<-SCRIPT
    Cookie.read('timeframe')
  SCRIPT
  p page.evaluate_script(script)
end

def execute_script(script, opts={})
  options = {
    :wait       => 1,
    :screenshot => false
  }.merge!(opts)

  page.execute_script(script)
  sleep(options[:wait])

  step 'show me the page' if options[:screenshot]
end


