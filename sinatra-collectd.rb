#!/usr/bin/env ruby

require 'rubygems'
Gem.clear_paths
__DIR__ = File.expand_path(File.dirname(__FILE__))
Gem.path << File.join(__DIR__, 'gems')
require 'sinatra'
require 'RRDtool'
require 'yajl'
require 'haml'

set :public, __DIR__ + '/public'
set :views,  __DIR__ + '/views'

template :layout do 
  File.read('views/layout.haml')
end

get '/' do 
  haml :index
end

get '/data/:host' do |host|
  encoder = Yajl::Encoder.new
  encoder.encode({host => 'bar'})
end
