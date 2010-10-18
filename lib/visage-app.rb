#!/usr/bin/env ruby

require 'pathname'
@root = Pathname.new(File.dirname(__FILE__)).parent.expand_path
$: << @root.to_s

require 'sinatra/base'
require 'haml'
require 'lib/visage-app/profile'
require 'lib/visage-app/helpers'
require 'lib/visage-app/config'
require 'lib/visage-app/config/file'
require 'lib/visage-app/collectd/rrds'
require 'lib/visage-app/collectd/json'
require 'yajl/json_gem'

module Visage
  class Application < Sinatra::Base
    @root = Pathname.new(File.dirname(__FILE__)).parent.expand_path
    set :public, @root.join('lib/visage-app/public')
    set :views,  @root.join('lib/visage-app/views')

    helpers Sinatra::LinkToHelper
    helpers Sinatra::PageTitleHelper

    configure do
      Visage::Config.use do |c|
        # Base configuration files.
        c['profiles']        = Visage::Config::File.load('profiles.yaml', :create => true, :ignore_bundled => true)
        c['plugin_colors']   = Visage::Config::File.load('plugin-colors.yaml')
        c['fallback_colors'] = Visage::Config::File.load('fallback-colors.yaml')

        # FIXME: make this configurable through file
        c['shade'] = false
        c['rrddir'] = ENV["RRDDIR"] ? Pathname.new(ENV["RRDDIR"]).expand_path : Pathname.new("/var/lib/collectd/rrd").expand_path
      end
    end
  end

  class Profiles < Application
    get '/' do
      redirect '/profiles'
    end

    get '/profiles/:url' do
      @profile = Visage::Profile.get(params[:url])
      raise Sinatra::NotFound unless @profile
      @start  = params[:start]
      @finish = params[:finish]
      haml :profile
    end

    get '/profiles' do
      @profiles = Visage::Profile.all(:sort => params[:sort])
      haml :profiles
    end
  end


  class Builder < Application

    get "/builder" do
      if params[:submit] == "create"
        @profile = Visage::Profile.new(params)

        if @profile.save
          redirect "/profiles/#{@profile.url}"
        else
          haml :builder
        end
      else
        @profile = Visage::Profile.new(params)

        haml :builder
      end
    end

    # infrastructure for embedding
    get '/javascripts/visage.js' do
      javascript = ""
      %w{raphael-min g.raphael g.line mootools-1.2.3-core mootools-1.2.3.1-more graph}.each do |js|
        javascript += File.read(@root.join('lib/visage-app/public/javascripts', "#{js}.js"))
      end
      javascript
    end

  end

  class JSON < Application

    # JSON data backend

    # /data/:host/:plugin/:optional_plugin_instance
    get %r{/data/([^/]+)/([^/]+)((/[^/]+)*)} do
      host = params[:captures][0].gsub("\0", "")
      plugin = params[:captures][1].gsub("\0", "")
      plugin_instances = params[:captures][2].gsub("\0", "")

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

    get %r{/data/([^/]+)} do
      host = params[:captures][0].gsub("\0", "")
      metrics = Visage::Collectd::RRDs.metrics(:host => host)

      json = { host => metrics }.to_json
      maybe_wrap_with_callback(json)
    end

    get %r{/data(/)*} do
      hosts = Visage::Collectd::RRDs.hosts
      json = { :hosts => hosts }.to_json
      maybe_wrap_with_callback(json)
    end

    # wraps json with a callback method that JSONP clients can call
    def maybe_wrap_with_callback(json)
      params[:callback] ? params[:callback] + '(' + json + ')' : json
    end

  end
end
