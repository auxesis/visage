#!/usr/bin/env ruby

require 'rubygems'

begin
  require 'cucumber/rake/task'

  Cucumber::Rake::Task.new do |t|
    t.binary = "bin/cucumber"
    t.cucumber_opts = "--require features/ features/"
  end
rescue LoadError
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "visage-app"
    gemspec.summary = "a web (interface | service) for viewing collectd statistics"
    gemspec.description = "Visage is a web interface for viewing collectd statistics. It also provides a JSON interface onto collectd's RRD data, giving you an easy way to mash up the data."
    gemspec.email = "lindsay@holmwood.id.au"
    gemspec.homepage = "http://auxesis.github.com/visage"
    gemspec.authors = ["Lindsay Holmwood"]

    gemspec.add_dependency "sinatra", "1.0"
    gemspec.add_dependency "tilt", "1.0.1"
    gemspec.add_dependency "haml", "3.0.13"
    gemspec.add_dependency "errand", "0.7.2"
    gemspec.add_dependency "yajl-ruby", "0.7.6"
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end
