#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'cucumber'
require 'cucumber/rake/task'
require 'rspec/core/rake_task'
require 'colorize'
require 'pathname'
$: << Pathname.new(__FILE__).join('lib').expand_path.to_s
require 'visage-app/version'

Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "features --format pretty"
end

RSpec::Core::RakeTask.new(:spec)

desc "build man pages"
task :man do
  man_glob = Pathname.new(__FILE__).parent.join('man').join('*.ronn').to_s
  Dir.glob(man_glob) do |man_page|
    sh "ronn --roff #{man_page}"
  end
end

desc "build gem"
task :build => [:man, :verify] do
  build_output = `gem build visage-app.gemspec`
  puts build_output

  gem_filename = build_output[/File: (.*)/,1]
  pkg_path = "pkg"
  FileUtils.mkdir_p(pkg_path)
  FileUtils.mv(gem_filename, pkg_path)

  puts "Gem built in #{pkg_path}/#{gem_filename}".green
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

desc "clean up various generated files"
task :clean do
  [ "webrat.log", "pkg/", "_site/"].each do |filename|
    puts "Removing #{filename}"
    FileUtils.rm_rf(filename)
  end
end

namespace :verify do
  desc "perform lintian checks on the JavaScript about to be shipped"
  task :lintian do
    @count = 0
    require 'pathname'
    @root = Pathname.new(File.dirname(__FILE__)).expand_path
    javascripts_path = @root.join('lib/visage-app/public/javascripts')

    javascripts = Dir.glob("#{javascripts_path + "*"}.js").reject {|f| f =~ /highcharts|mootools|src\.js/ }
    javascripts.each do |filename|
      puts "Checking #{filename}".green
      count = `grep -c 'console.log' #{filename}`.strip.to_i
      if count > 0
        puts "#{count} instances of console.log found in #{File.basename(filename)}".red
        @count += 1
      end
    end

    abort if @count > 0
  end

  task :changelog do
    changelog_filename = "CHANGELOG.md"
    version = Visage::VERSION

    if not system("grep ^#{version} #{changelog_filename} 2>&1 >/dev/null")
      puts "#{changelog_filename} doesn't have an entry for the version you are about to build.".red
      exit 1
    end
  end

  task :uncommitted do
    uncommitted = `git ls-files -m`.split("\n")
    if uncommitted.size > 0
      puts "The following files are uncommitted:".red
      uncommitted.each do |filename|
        puts " - #{filename}".red
      end
      exit 1
    end
  end

  task :all => [ :lintian, :changelog, :uncommitted ]
end

task :verify => 'verify:all'

task :default => [:spec,:features]


namespace :coffee do
  task :compile do
    cmd = %w(coffee)
    cmd << "--output lib/visage-app/public/javascripts/"
    cmd << "--join"

    # TODO(auxesis): add ability to pull in other arbitrary coffeescript
    %w(application models collections views profiles).each do |filename|
      cmd << "lib/visage-app/assets/coffeescripts/#{filename}.coffee"
    end

    command = cmd.join(' ')

    sh(command)
  end
end
