#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'cucumber'
require 'cucumber/rake/task'

Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "features --format pretty"
end

desc "build gem"
task :build => :lintian do
  build_output = `gem build visage-app.gemspec`
  puts build_output

  gem_filename = build_output[/File: (.*)/,1]
  pkg_path = "pkg"
  FileUtils.mkdir_p(pkg_path)
  FileUtils.mv(gem_filename, pkg_path)

  puts "Gem built in #{pkg_path}/#{gem_filename}"
end

desc "push gem"
task :push do
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
  @count = 0
  require 'pathname'
  @root = Pathname.new(File.dirname(__FILE__)).expand_path
  javascripts_path = @root.join('lib/visage-app/public/javascripts')

  javascripts = Dir.glob("#{javascripts_path + "*"}.js").reject {|f| f =~ /mootools|src\.js/ }
  javascripts.each do |filename|
    puts "Checking #{filename}"
    count = `grep -c 'console.log' #{filename}`.strip.to_i
    if count > 0
      puts "#{count} instances of console.log found in #{File.basename(filename)}"
      @count += 1
    end
  end

  abort if @count > 0
end

desc "clean up various generated files"
task :clean do
  [ "webrat.log", "pkg/", "_site/"].each do |filename|
    puts "Removing #{filename}"
    FileUtils.rm_rf(filename)
  end
end
