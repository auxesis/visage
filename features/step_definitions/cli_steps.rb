Given /^the visage server helper is not running$/ do
  require 'socket'

  lambda {
    fqdn   = Socket.gethostbyname(Socket.gethostname).first
    socket = TCPSocket.new(fqdn, 9292)
  }.should raise_error(Errno::ECONNREFUSED)
end

When /^I start the visage server helper with "([^"]*)"$/ do |cmd|
  @root = Pathname.new(File.dirname(__FILE__)).parent.parent.expand_path
  command = "#{@root.join('bin')}/#{cmd}"

  @pipe = spawn_daemon(command)
end

Then /^a visage web server should be running$/ do
  `ps -eo cmd |grep ^visage`.size.should > 0
end

Then /^a visage web server should not be running$/ do
  `ps -eo cmd |grep ^visage`.size.should == 0
end

Then /^I should see a man page$/ do
  output = read_until_timeout(@pipe)

  headings = %w(VISAGE-APP NAME DESCRIPTION SYNOPSIS COPYRIGHT)

  headings.each do |heading|
    output.find {|line| line =~ /^#{heading}/}.should_not be_nil
  end
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

Given /^I am using a profile based on "(.*?)"$/ do |directory|
  root        = Pathname.new(__FILE__).parent.parent.join('support/config')
  source      = root.join(directory).join('profiles.yaml')
  destination = root.join('tmp').join('profiles.yaml')

  source.exist?.should be_true
  FileUtils.rm(destination) if destination.exist?
  FileUtils.cp(source.to_s, destination.to_s)

  ENV['CONFIG_PATH'] = destination.parent.to_s
end

Given /^a profile file doesn't exist$/ do
  root        = Pathname.new(__FILE__).parent.parent.join('support/config')
  destination = root.join('tmp').join('profiles.yaml')

  FileUtils.rm(destination) if destination.exist?
  ENV['CONFIG_PATH'] = destination.parent.to_s
end

Then /^I should see a profile file has been created$/ do
  root        = Pathname.new(__FILE__).parent.parent.join('support/config')
  destination = root.join('tmp').join('profiles.yaml')

  destination.exist?.should be_true
end
