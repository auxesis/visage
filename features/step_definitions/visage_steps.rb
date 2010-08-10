Given /^the "([^"]*)" gem is installed$/ do |name|
  `gem list #{name} |grep #{name}`.size.should > 0
end

When /^I start the visage server helper with "([^"]*)"$/ do |cmd|
  @root = Pathname.new(File.dirname(__FILE__)).parent.parent.expand_path
  command = "#{@root.join('bin')}/#{cmd}"

  @pipe = IO.popen(command, "r")
  sleep 2 # so the visage server has a chance to boot

  # clean up the visage server when the tests finish
  at_exit do
    Process.kill("KILL", @pipe.pid)
  end
end

Then /^a visage web server should be running$/ do
  `ps -eo cmd |grep ^visage`.size.should > 0
end

Then /^I should see "([^"]*)" on the terminal$/ do |string|
  output = @pipe.read(250)
  output.should =~ /#{string}/
end
