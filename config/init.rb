__DIR__ = File.expand_path(File.join(File.dirname(__FILE__)))
require File.join(__DIR__, '..', 'lib', 'visage-config')

Visage::Config.use do |c|
  c['color_mappings'] = YAML::load(File.read(File.join(__DIR__, 'colors.yaml')))
 
  c['config_filename'] = File.expand_path(File.join(__DIR__, 'config.yaml'))
  YAML::load(File.read(c['config_filename'])).each_pair do |key, value|
    c[key] = value
  end

  c['rrddir'] = "/var/lib/collectd/rrd"
end

