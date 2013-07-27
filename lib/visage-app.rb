#!/usr/bin/env ruby

require 'pathname'
@root = Pathname.new(File.dirname(__FILE__)).expand_path
$: << @root.to_s

require 'sinatra/base'
require 'sinatra/reloader'
require 'haml'
require 'visage-app/models/profile'
require 'visage-app/helpers'
require 'visage-app/config'
require 'visage-app/config/file'
require 'visage-app/data'
require 'yajl/json_gem'

module Visage
  class Application < Sinatra::Base
    @root = Pathname.new(File.dirname(__FILE__)).expand_path
    set :public_folder, @root.join('visage-app/public')
    set :views,         @root.join('visage-app/views')

    enable :logging

    helpers Sinatra::LinkToHelper
    helpers Sinatra::PageTitleHelper
    helpers Sinatra::RequireJSHelper
    helpers Sinatra::RequireCSSHelper
    helpers Sinatra::FormatHelper

    configure do
      Visage::Config.use do |c|
        # FIXME: make this configurable through a YAML config file
        c['data_backend']  = ENV['VISAGE_DATA_BACKEND'] || 'RRD'

        # RRD specific config options
        # FIXME: make this configurable through a YAML config file
        c['rrddir']        = ENV["RRDDIR"] ? Pathname.new(ENV["RRDDIR"]).expand_path : Pathname.new("/var/lib/collectd/rrd").expand_path
        c['collectdsock']  = ENV["COLLECTDSOCK"]
        c['rrdcachedsock'] = ENV["RRDCACHEDSOCK"]
      end

#      # Upgrade the profile if we're running an older version
#      Visage::Profile.upgrade if Profile.version != "3.0.0"

      # Set the data backend to use in Visage::JSON
      Visage::Data.backend = Visage::Config.data_backend
    end

    configure :development do
      register Sinatra::Reloader
    end
  end

  class Profiles < Application
    get '/' do
      redirect '/profiles'
    end

    get '/profiles/new' do
      haml :profile
    end

    get '/profiles/share/:id' do
      Profile.all(:sort => :created_at, :anonymous => true)
      Profile.all(:sort => :created_at)

      @profile = Profile.get(params[:id])
      raise Sinatra::NotFound unless @profile

      haml :share, :layout => false
    end

    get %r{/profiles/([^/\.]+).?([^/]+)?} do
      url    = params[:captures][0]
      format = params[:captures][1]

      @profile = Profile.get(url)
      raise Sinatra::NotFound unless @profile

      if format == 'json'
        @profile.to_json
      else
        haml :profile
      end
    end

    get %r{/profiles/*} do
      named_options = {
        :anonymous => false,
        :order     => params[:order],
        :sort      => params[:sort] || :name,
      }
      @profiles  = Profile.all(named_options)

      anonymous_options = {
        :anonymous => true,
        :sort      => :created_at,
        :order     => 'ascending',
      }
      @anonymous = Profile.all(anonymous_options)

      haml :profiles
    end

    post '/profiles' do
      attributes = ::JSON.parse(request.body.read).symbolize_keys
      @profile = Profile.new(attributes)

      if @profile.save
        {'status' => 'ok', 'id' => @profile.id}.to_json
      else
        status 400 # Bad Request
        {'status' => 'error', 'errors' => @profile.errors}.to_json
      end
    end

    post %r{/profiles/([^/\.]+).?([^/]+)?} do
      url    = params[:captures][0]
      format = params[:captures][1]

      attrs = ::JSON.parse(request.body.read)
      @profile = Profile.new(attrs)

      @profile = Profile.get(url)
      raise Sinatra::NotFound unless @profile

      if @profile.save
        {'status' => 'ok', 'id' => @profile.url}.to_json
      else
        status 400 # Bad Request
        {'status' => 'error', 'errors' => @profile.errors}.to_json
      end
    end
  end


  class Builder < Application
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
      content_type :json if headers["Content-Type"] =~ /text/

      host        = params[:captures][0].gsub("\0", "")
      plugin      = params[:captures][1].gsub("\0", "")
      instances   = params[:captures][2].gsub("\0", "")
      start       = params[:start]
      finish      = params[:finish]
      percentiles = params[:percentiles] ||= "false"
      resolution  = params[:resolution]

      options = {
        :rrddir        => Visage::Config.rrddir,
        :collectdsock  => Visage::Config.collectdsock,
        :rrdcachedsock => Visage::Config.rrdcachedsock
      }
      data = Visage::Data.new(options)

      query = {
        :host        => host,
        :plugin      => plugin,
        :instances   => instances,
        :start       => start,
        :finish      => finish,
        :percentiles => percentiles,
        :resolution  => resolution,
      }
      json = data.json(query)

      # If the request is cross-domain, we need to serve JSON-P.
      maybe_wrap_with_callback(json)
    end

    get %r{/data/([^/]+)} do
      content_type :json if headers["Content-Type"] =~ /text/

      query = {
        :hosts => params[:captures][0].gsub("\0", "")
      }
      metrics = Visage::Data.metrics(query)
      json = { :metrics => metrics }.to_json

      maybe_wrap_with_callback(json)
    end

    get %r{/data(/)*} do
      content_type :json if headers["Content-Type"] =~ /text/

      hosts = Visage::Data.hosts
      json  = { :hosts => hosts }.to_json

      maybe_wrap_with_callback(json)
    end

    # Wraps json with a callback method that JSON-P clients can call.
    def maybe_wrap_with_callback(json)
      params[:callback] ? params[:callback] + '(' + json + ')' : json
    end

  end
end
