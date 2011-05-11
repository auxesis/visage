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
    gemspec.name        = "visage-app"
    gemspec.summary     = "a web (interface | service) for viewing collectd statistics"
    gemspec.description = "Visage is a web interface for viewing collectd statistics. It also provides a JSON interface onto collectd's RRD data, giving you an easy way to mash up the data."
    gemspec.email       = "lindsay@holmwood.id.au"
    gemspec.homepage    = "http://visage-app.com/"
    gemspec.authors     = ["Lindsay Holmwood"]

    gemspec.add_dependency "sinatra", "~> 1.1.3"
    gemspec.add_dependency "tilt", "~> 1.2.2"
    gemspec.add_dependency "haml", "~> 3.0.13"
    gemspec.add_dependency "errand", "= 0.7.3"
    gemspec.add_dependency "yajl-ruby", "~> 0.8.1"
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end

desc "push gem"
task :push => :lintian do
  filenames = Dir.glob("pkg/*.gem")
  filenames_with_times = filenames.map do |filename|
    [filename, File.mtime(filename)]
  end

  newest = filenames_with_times.sort_by { |tuple| tuple.last }.last
  newest_filename = newest.first

  command = "gem push #{newest_filename}"
  system(command)
end

desc "perform lintian checks on the JavaScript about to be shipped"
task :lintian do
  require 'pathname'
  @root = Pathname.new(File.dirname(__FILE__)).expand_path
  javascripts_path = @root.join('lib/visage-app/public/javascripts')

  count = `grep -c 'console.log' #{javascripts_path.join('graph.js')}`.strip.to_i
  abort("#{count} instances of console.log found in graph.js!") if count > 0
end

desc "clean up various generated files"
task :clean do
  [ "webrat.log", "pkg/", "visage-app-*.spec", "_site/"].each do |filename|
    puts "Removing #{filename}"
    FileUtils.rm_rf(filename)
  end
end
