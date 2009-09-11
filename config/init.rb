__DIR__ = File.expand_path(File.join(File.dirname(__FILE__)))
require File.join(__DIR__, '..', 'lib', 'visage-config')

Visage::Config.use do |c|
  c['fallback_colors'] = YAML::load(File.read(File.join(__DIR__, 'colors.yaml')))
 
  profile_filename = File.join(__DIR__, 'profiles.yaml')
  unless File.exists?(profile_filename)
    puts "You need to specify a list of profiles in config/profile.yaml!"
    puts "Check out config/profiles.yaml.sample for an example."
    exit 1
  end
  YAML::load(File.read(profile_filename)).each_pair do |key, value|
    c[key] = value
  end

  plugin_colors_filename = File.join(__DIR__, 'plugin-colors.yaml')
  unless File.exists?(plugin_colors_filename)
    puts "It's highly recommended you specify graph line colors in config/plugin-colors.yaml!"
  end
  YAML::load(File.read(plugin_colors_filename)).each_pair do |key, value|
    c[key] = value
  end

  c['rrddir'] = "/var/lib/collectd/rrd"
end

