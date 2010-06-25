#!/usr/bin/env ruby

require 'pathname'
@root = Pathname.new(File.dirname(__FILE__)).parent.expand_path
$: << @root.to_s

require 'sinatra'
require 'errand'
require 'yajl'
require 'haml'
require 'lib/visage/config'
require 'lib/visage/helpers'
require 'lib/visage/config/init'
require 'lib/visage/collectd/json'

set :public, @root.join('lib/visage/public')
set :views,  @root.join('lib/visage/views')

configure do
  CollectdJSON.rrddir = Visage::Config.rrddir
  Visage::Config::Profiles.profiles = Visage::Config.profiles
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
get %r{/data/([^/]+)/([^/]+)((/[^/]+)*)} do
  host = params[:captures][0]
  plugin = params[:captures][1]
  plugin_instances = params[:captures][2]

  collectd = CollectdJSON.new(:rrddir => Visage::Config.rrddir,
                              :fallback_colors => Visage::Config.fallback_colors)
  json = collectd.json(:host => host,
                       :plugin => plugin,
                       :plugin_instances => plugin_instances,
                       :start => params[:start],
                       :finish => params[:finish],
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
