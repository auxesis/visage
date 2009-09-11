__DIR__ = File.expand_path(File.join(File.dirname(__FILE__)))
require File.join(__DIR__, '..', 'lib', 'visage-config')

Visage::Config.use do |c|
  c['fallback_colors'] = YAML::load(File.read(File.join(__DIR__, 'colors.yaml')))
 
  profile_filename = File.join(__DIR__, 'profiles.yaml')
  YAML::load(File.read(profile_filename)).each_pair do |key, value|
    c[key] = value
  end

  plugin_colors_filename = File.join(__DIR__, 'plugin-colors.yaml')
  YAML::load(File.read(plugin_colors_filename)).each_pair do |key, value|
    c[key] = value
  end

  c['rrddir'] = "/var/lib/collectd/rrd"
end

