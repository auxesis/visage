#!/usr/bin/env ruby

require 'rubygems'

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
  [ "webrat.log", "pkg/", "_site/"].each do |filename|
    puts "Removing #{filename}"
    FileUtils.rm_rf(filename)
  end
end
