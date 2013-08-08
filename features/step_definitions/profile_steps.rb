When /^I add a graph$/ do
  script = <<-SCRIPT
    $$('div#hosts input.checkbox')[0].click();
    $$('div#metrics input.checkbox')[0].click();
    $$('div#display input.button')[0].click();
  SCRIPT
  page.execute_script(script)

  sleep 2 # so the graphs have time to render
end

When /^I share the profile$/ do
  script = <<-SCRIPT
    $('share-toggler').fireEvent('click');
  SCRIPT
  page.execute_script(script)

  sleep 2 # so the toggler has time to render
end

Then /^I should see a permalink for the profile$/ do
  #page.current_path.should_not match(/\/profiles\/new$/)
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
    $('save').fireEvent('click');
  SCRIPT
  execute_script(script)
end

Then(/^I should see a profile named "(.*?)"$/) do |name|
  doc = Nokogiri::HTML(page.body)
  profiles = doc.search('div#named_profiles ul li')
  profiles.size.should > 0

  match = profiles.find {|profile| profile.text =~ /#{name}/}
  match.should_not be_nil
end

def execute_script(script, opts={})
  options = {
    :wait => 1,
    :snapshot => false
  }.merge!(opts)

  page.execute_script(script)
  sleep(options[:wait])

  step 'show me the page' if options[:snapshot]
end

