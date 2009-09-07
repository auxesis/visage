#!/usr/bin/env ruby 

require 'rubygems'
Gem.clear_paths
Gem.path.unshift(File.join(File.dirname(__FILE__), 'gems'))

begin 
  require 'cucumber/rake/task'
   
  Cucumber::Rake::Task.new do |t|
    t.binary = "bin/cucumber"
    t.cucumber_opts = "--require features/ features/"
  end
rescue LoadError
end


desc "freeze deps"
task :deps do 

  deps = {'cucumber' => '= 0.3.98',
          'rspec' => '= 1.2.8',
          'webrat' => '= 0.5.3', 
          'rack-test' => '= 0.4.1', 
          'rake' => '= 0.8.7',
          'sinatra' => '= 0.9.4', 
          'haml' => '= 2.0.5',
          'RubyRRDtool' => '= 0.6.0',
          'yajl-ruby' => '= 0.6.3'}

  puts "\ninstalling dependencies. this will take a few minutes."

  deps.each_pair do |dep, version|
    if Dir.glob("gems/gems/#{dep}-#{version.split.last}").size > 0
      next unless ENV["FORCE"]
    end
    puts "\ninstalling #{dep} (#{version})"
    system("gem install #{dep} --version '#{version}' -i gems --no-rdoc --no-ri")
  end

end
