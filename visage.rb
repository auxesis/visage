#!/usr/bin/env ruby

require 'rubygems'
Gem.clear_paths
__DIR__ = File.expand_path(File.dirname(__FILE__))
Gem.path << File.join(__DIR__, 'gems')
require 'sinatra'
require 'errand'
require 'yajl'
require 'haml'
require 'lib/collectd-json'
require 'lib/visage-config'

set :public, __DIR__ + '/public'
set :views,  __DIR__ + '/views'

configure do 
  require 'config/init'

  CollectdJSON.rrddir = Visage::Config.rrddir
  Visage::Config::Profiles.profiles = Visage::Config.profiles
end

template :layout do 
  File.read('views/layout.haml')
end

# infrastructure for embedding
get '/javascripts/visage.js' do
  javascript = ""
  %w{raphael-min g.raphael g.line mootools-1.2.3-core mootools-1.2.3.1-more graph}.each do |js|
    javascript += File.read(File.join(__DIR__, 'public', 'javascripts', "#{js}.js"))
  end
  javascript
end

# user facing
get '/' do 
  @hosts = CollectdJSON.hosts
  haml :index
end

get '/:host' do 
  @hosts = CollectdJSON.hosts
  @profiles = Visage::Config::Profiles.all

  haml :index
end

get '/:host/:profile' do 
  @hosts = CollectdJSON.hosts
  @profiles = Visage::Config::Profiles.all
  @profile = Visage::Config::Profiles.get(params[:profile])
  
  haml :index
end

# JSON data backend

# /data/:host/:plugin/:optional_plugin_instance
get %r{/data/([^/]+)/([^/]+)(/([^/]+))*} do 
  host = params[:captures][0]
  plugin = params[:captures][1]
  plugin_instance = params[:captures][3]

  collectd = CollectdJSON.new(:rrddir => Visage::Config.rrddir, 
                              :fallback_colors => Visage::Config.fallback_colors)
  json = collectd.json(:host => host, 
                       :plugin => plugin,
                       :plugin_instance => plugin_instance,
                       :start => params[:start],
                       :end => params[:end],
                       :plugin_colors => Visage::Config.plugin_colors)
  # if the request is cross-domain, we need to serve JSONP
  maybe_wrap_with_callback(json)
end

# wraps json with a callback method that JSONP clients can call
def maybe_wrap_with_callback(json)
  if params[:callback]
    params[:callback] + '(' + json + ')'
  else
    json
  end
end
