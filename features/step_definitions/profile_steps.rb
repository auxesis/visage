When /^I show a graph for a host$/ do
  script = <<-SCRIPT
    $$('div#hosts input.checkbox')[0].checked = true;
    $$('div#metrics input.checkbox')[0].checked = true;
    $$('div#display input.button')[0].click();
  SCRIPT
  page.execute_script(script)
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


