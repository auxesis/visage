#!/usr/bin/env ruby

require 'pathname'
@root = Pathname.new(File.dirname(__FILE__)).expand_path
$: << @root.to_s

require 'sinatra/base'
require 'sinatra/reloader'
require 'haml'
require 'yajl/json_gem'
require 'visage-app/models/profile'
require 'visage-app/helpers'
require 'visage-app/config'
require 'visage-app/data'
require 'visage-app/upgrade'

module Sinatra
  module PutOrPost
    def put_or_post(path,options={},&block)
      put(path,options,&block)
      post(path,options,&block)
    end
  end

  register PutOrPost
end

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

    register Sinatra::PutOrPost

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

      # Upgrade the profile if we're running an older version
      if Visage::Upgrade.pending?
        puts "The Visage profile storage format has changed."
        upgrades = Visage::Upgrade.run
        first    = upgrades.first.version - 1
        last     = upgrades.last.version
        puts "Upgraded profile storage format from version #{first} to #{last}"
      end

      # Set the data backend to use in Visage::JSON
      Visage::Data.backend = Visage::Config.data_backend
    end

    configure :development do
      register Sinatra::Reloader
    end

    configure :test do
      disable :logging
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
      @profile = Profile.get(params[:id])
      raise Sinatra::NotFound unless @profile

      haml :share, :layout => false
    end

    # Viewing a single profile
    get %r{/profiles/([^/\.]+).?([^/]+)?} do
      id     = params[:captures][0]
      format = params[:captures][1]

      @profile = Profile.get(id)
      raise Sinatra::NotFound unless @profile

      if format == 'json'
        @profile.to_json
      else
        haml :profile
      end
    end

    # Viewing all profiles
    get %r{/profiles/*} do
      named_options = {
        :anonymous => false,
        :sort      => :name,
      }
      @profiles  = Profile.all(named_options)

      anonymous_options = {
        :anonymous => true,
        :sort      => :created_at,
        :order     => :descending,
      }
      @anonymous = Profile.all(anonymous_options)

      haml :profiles
    end

    # Creating a new profile
    post '/profiles' do
      attributes = ::JSON.parse(request.body.read).symbolize_keys
      filter_parameters!(attributes)
      @profile = Profile.new(attributes)

      if @profile.save
        {'status' => 'ok', 'id' => @profile.id}.to_json
      else
        status 400 # Bad Request
        {'status' => 'error', 'errors' => @profile.errors}.to_json
      end
    end

    # Updating an existing profile
    put_or_post %r{/profiles/([^/\.]+).?([^/]+)?} do
      id     = params[:captures][0]
      format = params[:captures][1]

      @profile = Profile.get(id)
      raise Sinatra::NotFound unless @profile

      if format == 'json'
        attributes = ::JSON.parse(request.body.read).symbolize_keys
      else
        attributes = params['profile'].symbolize_keys
      end
      filter_parameters!(attributes)

      if @profile.update_attributes(attributes)
        {'status' => 'ok', 'id' => @profile.id}.to_json
      else
        status 400 # Bad Request
        {'status' => 'error', 'errors' => @profile.errors}.to_json
      end
    end

    delete %r{/profiles/([^/\.]+).?([^/]+)?} do
      id     = params[:captures][0]
      format = params[:captures][1]

      @profile = Profile.get(id)
      raise Sinatra::NotFound unless @profile

      if @profile.destroy
        {'status' => 'ok', 'id' => @profile.id}.to_json
      else
        status 400 # Bad Request
        {'status' => 'error', 'errors' => @profile.errors}.to_json
      end
    end

    private
    def filter_parameters!(attributes)
      allowed = [ :id, :name, :graphs, :anonymous, :created_at, :timeframe, :tags ]
      attributes.reject! {|k,v| !allowed.include?(k) }
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
