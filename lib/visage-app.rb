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
        c['rrddir']        = ENV["RRDDIR"] ? Pathname.new(ENV["RRDDIR"]).expand_path : Pathname.new("/var/lib/collectd/rrd").expand_path
        c['types']         = ENV["TYPES"]  ? Visage::Types.new(:filename => ENV["TYPES"]) : Visage::Types.new
        c['collectdsock']  = ENV["COLLECTDSOCK"]
        c['rrdcachedsock'] = ENV["RRDCACHEDSOCK"]
      end

      # Load up the profiles.yaml. Creates it if it doesn't already exist.
      Visage::Profile.load

    end
  end

  class Profiles < Application
    get '/' do
      redirect '/profiles'
    end

    get %r{/profiles/([^/\.]+).?([^/]+)?} do
      url    = params[:captures][0]
      format = params[:captures][1]

      @profile = Visage::Profile.get(url)
      raise Sinatra::NotFound unless @profile

      if format == 'json'
        @profile.to_json
      else
        haml :rebuilder
      end
    end

    get '/profiles' do
      @profiles = Visage::Profile.all(:sort => params[:sort])
      haml :profiles
    end

    post '/profiles' do
      attrs = ::JSON.parse(request.body.read)
      @profile = Visage::Profile.new(attrs)

      if @profile.save
        {'status' => 'ok'}.to_json
      else
        status 400 # Bad Request
        {'status' => 'error', 'errors' => @profile.errors}.to_json
      end
    end
  end


  class Builder < Application

    get '/rebuilder' do
      haml :rebuilder
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
      content_type :json if headers["Content-Type"] =~ /text/

      host        = params[:captures][0].gsub("\0", "")
      plugin      = params[:captures][1].gsub("\0", "")
      instances   = params[:captures][2].gsub("\0", "")
      start       = params[:start]
      finish      = params[:finish]
      percentiles = params[:percentiles] ||= "false"
      resolution  = params[:resolution]

      collectd = Visage::Collectd::JSON.new(:rrddir        => Visage::Config.rrddir,
                                            :collectdsock  => Visage::Config.collectdsock,
                                            :rrdcachedsock => Visage::Config.rrdcachedsock)

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
      content_type :json if headers["Content-Type"] =~ /text/

      hosts = params[:captures][0].gsub("\0", "")
      metrics = Visage::Collectd::RRDs.metrics(:hosts => hosts)

      json = { :metrics => metrics }.to_json
      maybe_wrap_with_callback(json)
    end

    get %r{/data(/)*} do
      content_type :json if headers["Content-Type"] =~ /text/
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
