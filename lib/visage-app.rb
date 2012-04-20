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
require 'lib/visage-app/types'
require 'yajl/json_gem'

module Visage
  class Application < Sinatra::Base
    @root = Pathname.new(File.dirname(__FILE__)).parent.expand_path
    set :public_folder, @root.join('lib/visage-app/public')
    set :views,         @root.join('lib/visage-app/views')

    enable :logging

    helpers Sinatra::LinkToHelper
    helpers Sinatra::PageTitleHelper
    helpers Sinatra::RequireJSHelper

    configure do
      Visage::Config.use do |c|
        # FIXME: make this configurable through file
        c['rrddir'] = ENV["RRDDIR"] ? Pathname.new(ENV["RRDDIR"]).expand_path : Pathname.new("/var/lib/collectd/rrd").expand_path
        c['types']  = ENV["TYPES"]  ? Visage::Types.new(:filename => ENV["TYPES"]) : Visage::Types.new
      end

      # Load up the profiles.yaml. Creates it if it doesn't already exist.
      Visage::Profile.load

    end
  end

  class Profiles < Application
    get '/' do
      redirect '/profiles'
    end

    get '/profiles/:url' do
      @profile = Visage::Profile.get(params[:url])
      raise Sinatra::NotFound unless @profile
      haml :profile
    end

    get '/profiles' do
      @profiles = Visage::Profile.all(:sort => params[:sort])
      haml :profiles
    end
  end


  class Builder < Application

    post '/builder' do
      @profile = Visage::Profile.new(params)

      if @profile.save
        {'status' => 'ok'}.to_json
      else
        status 400 # Bad Request
        {'status' => 'error', 'errors' => @profile.errors}.to_json
      end
    end

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

    # Infrastructure for embedding.
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
    mime_type :json,  "application/json"
    mime_type :jsonp, "text/javascript"

    before do
      content_type :jsonp
    end

    # /data/:host/:plugin/:optional_plugin_instance
    get %r{/data/([^/]+)/([^/]+)((/[^/]+)*)} do
      host        = params[:captures][0].gsub("\0", "")
      plugin      = params[:captures][1].gsub("\0", "")
      instances   = params[:captures][2].gsub("\0", "")
      start       = params[:start]
      finish      = params[:finish]
      percentiles = params[:percentiles] ||= "false"
      resolution  = params[:resolution]

      collectd = Visage::Collectd::JSON.new(:rrddir => Visage::Config.rrddir)

      json = collectd.json(:host        => host,
                           :plugin      => plugin,
                           :instances   => instances,
                           :start       => start,
                           :finish      => finish,
                           :percentiles => percentiles,
                           :resolution  => resolution)

      # If the request is cross-domain, we need to serve JSON-P.
      maybe_wrap_with_callback(json)
    end

    get %r{/data/([^/]+)} do
      hosts = params[:captures][0].gsub("\0", "")
      metrics = Visage::Collectd::RRDs.metrics(:hosts => hosts)

      json = { :metrics => metrics }.to_json
      maybe_wrap_with_callback(json)
    end

    get %r{/data(/)*} do
      hosts = Visage::Collectd::RRDs.hosts
      json = { :hosts => hosts }.to_json
      maybe_wrap_with_callback(json)
    end

    # Wraps json with a callback method that JSON-P clients can call.
    def maybe_wrap_with_callback(json)
      params[:callback] ? params[:callback] + '(' + json + ')' : json
    end

  end

  class Meta < Application
    get '/meta/types' do
      Visage::Config.types.to_json
    end
  end
end
