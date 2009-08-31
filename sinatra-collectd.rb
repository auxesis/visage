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

set :public, __DIR__ + '/public'
set :views,  __DIR__ + '/views'

configure do 
  @rrddir = "/var/lib/collectd/rrd"
  CollectdJSON.basedir = @rrddir
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
  profile = CollectdProfile.get(params[:profile])
  
  haml :index
end


# JSON data backend
get '/data/:host/:plugin/:plugin_instance' do 
  collectd = CollectdJSON.new(:basedir => @rrddir)
  collectd.json(:host => params[:host], 
                :plugin => params[:plugin], 
                :plugin_instance => params[:plugin_instance],
                :start => params[:start],
                :end => params[:end])
end

get '/data/:host/:profile' do 
  profile = CollectdProfile.get(params[:profile])
end

