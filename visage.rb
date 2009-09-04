#!/usr/bin/env ruby

require 'rubygems'
Gem.clear_paths
__DIR__ = File.expand_path(File.dirname(__FILE__))
Gem.path << File.join(__DIR__, 'gems')
require 'sinatra'
require 'RRDtool'
require 'yajl'
require 'haml'
require 'lib/collectd-json'
require 'lib/collectd-profile'

set :public, __DIR__ + '/public'
set :views,  __DIR__ + '/views'

configure do 
  RRDDIR = "/var/lib/collectd/rrd"
  @config_filename = File.expand_path(File.join(__DIR__, 'config.yaml'))
  CONFIG_FILENAME = @config_filename

  CollectdJSON.basedir = RRDDIR
  CollectdProfile.config_filename = @config_filename
end

template :layout do 
  File.read('views/layout.haml')
end

# user facing
get '/' do 
  @hosts = CollectdJSON.hosts
  haml :index
end

get '/:host' do 
  @hosts = CollectdJSON.hosts

  haml :index
end

get '/:host/:profile' do 
  @hosts = CollectdJSON.hosts
  @profile = CollectdProfile.get(params[:profile])
  
  haml :index
end

# JSON data backend
get '/data/:host/:plugin/' do 
  config = YAML::load(File.read(CONFIG_FILENAME))

  collectd = CollectdJSON.new(:basedir => RRDDIR)
  collectd.json(:host => params[:host], 
                :plugin => params[:plugin], 
                :start => params[:start],
                :end => params[:end],
                :colors => config['colors'])
end

get '/data/:host/:plugin/:plugin_instance' do 
  config = YAML::load(File.read(CONFIG_FILENAME))

  collectd = CollectdJSON.new(:basedir => RRDDIR)
  collectd.json(:host => params[:host], 
                :plugin => params[:plugin], 
                :plugin_instance => params[:plugin_instance],
                :start => params[:start],
                :end => params[:end],
                :colors => config['colors'])
end

