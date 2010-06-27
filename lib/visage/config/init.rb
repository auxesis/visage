#!/usr/bin/env ruby

@root = Pathname.new(File.dirname(__FILE__)).parent.parent.parent.expand_path
@config_directory = Pathname.new(File.dirname(__FILE__)).expand_path
require @root.join('lib/visage/config')
require 'yaml'

Visage::Config.use do |c|
  # setup profiles file
  profile_filename = @config_directory.join('profiles.yaml')
  unless File.exists?(profile_filename)
    FileUtils.touch(profile_filename)
  end

  # setup plugin colors file
  plugin_colors_filename = @config_directory.join('plugin-colors.yaml')
  unless File.exists?(plugin_colors_filename)
    puts "It's highly recommended you specify graph line colors in config/plugin-colors.yaml!"
  end

  # load config from profiles + plugin colors file
  [profile_filename, plugin_colors_filename].each do |filename|
    if File.exists?(filename)
      config = YAML::load_file(filename) || {}
      config.each_pair {|key, value| c[key] = value}
    end
  end

  # load fallback colors
  c['fallback_colors'] = YAML::load(File.read(@config_directory.join('fallback-colors.yaml')))

  # Location of collectd's RRD - you may want to edit this!
  c['rrddir'] = "/var/lib/collectd/rrd"

  # whether to shade in graphs
  c['shade'] = false
end

