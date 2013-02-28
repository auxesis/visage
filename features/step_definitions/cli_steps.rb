When /^I start the visage server helper with "([^"]*)"$/ do |cmd|
  @root = Pathname.new(File.dirname(__FILE__)).parent.parent.expand_path
  command = "#{@root.join('bin')}/#{cmd}"

  @pipe = spawn_daemon(command)
end

Then /^a visage web server should be running$/ do
  `ps -eo cmd |grep ^visage`.size.should > 0
end

Then /^I should see "([^"]*)" on the terminal$/ do |string|
  output = read_until_timeout(@pipe).join('')
  output.should =~ /#{string}/
end

Given /^there is no file at "([^"]*)"$/ do |filename|
  FileUtils.rm_f(filename).should be_true
end

When /^I start the visage server helper with "([^"]*)" and the following variables:$/ do |cmd, table|
  table.hashes.each do |hash|
    hash.each_pair do |variable, value|
      ENV[variable] = value
    end
  end
  step %(I start the visage server helper with "#{cmd}")
end

Then /^I should see a file at "([^"]*)"$/ do |filename|
  File.exists?(filename).should be_true
end

Then /^show me the output$/ do
  puts @pipe.read(350)
end
