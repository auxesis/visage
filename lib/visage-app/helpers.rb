#!/usr/bin/env ruby

require 'sinatra/base'

module Sinatra
  module LinkToHelper
    # from http://gist.github.com/98310
    def link_to(url_fragment, mode=:path_only)
      case mode
      when :path_only
        base = request.script_name
      when :full_url
        if (request.scheme == 'http' && request.port == 80 ||
            request.scheme == 'https' && request.port == 443)
          port = ""
        else
          port = ":#{request.port}"
        end
        base = "#{request.scheme}://#{request.host}#{port}#{request.script_name}"
      else
        raise "Unknown script_url mode #{mode}"
      end
      "#{base}#{url_fragment}"
    end
  end

  module PageTitleHelper
    def page_title(string)
      @page_title = string
    end

    def include_page_title
      @page_title ? "#{@page_title} | Visage" : "Visage"
    end
  end

  module RequireJSHelper
    def require_js(filename)
      @js_filenames ||= []
      @js_filenames << filename
    end

    def include_required_js
      if @js_filenames
        @js_filenames.map { |filename|
          "<script type='text/javascript' src='#{link_to("/javascripts/#{filename}.js")}'></script>"
        }.join("\n")
      else
        ""
      end
    end
  end

  module FormatHelper
    def distance_of_time_in_words(from_time, to_time = Time.now.to_i, include_seconds = false)
      from_time = from_time.to_i
      distance_in_minutes = (((to_time - from_time).abs)/60).round
      distance_in_seconds = ((to_time - from_time).abs).round

      case distance_in_minutes
        when 0..1
          return (distance_in_minutes==0) ? 'less than a minute ago' : '1 minute ago' unless include_seconds
          case distance_in_seconds
            when 0..5   then 'less than 5 seconds ago'
            when 6..10  then 'less than 10 seconds ago'
            when 11..20 then 'less than 20 seconds ago'
            when 21..40 then 'half a minute ago'
            when 41..59 then 'less than a minute ago'
            else             '1 minute ago'
          end

          when 2..45           then "#{distance_in_minutes} minutes ago"
          when 46..90          then 'about 1 hour ago'
          when 90..1440        then "about #{(distance_in_minutes / 60).round} hours ago"
          when 1441..2880      then '1 day ago'
          when 2881..43220     then "#{(distance_in_minutes / 1440).round} days ago"
          when 43201..86400    then 'about 1 month ago'
          when 86401..525960   then "#{(distance_in_minutes / 43200).round} months ago"
          when 525961..1051920 then 'about 1 year ago'
        else                      "over #{(distance_in_minutes / 525600).round} years ago"
      end
    end


    def truncate(text, opts={})
      options = { :length => 30, :omission => "..."}.merge(opts)
      if text
        len = options[:length] - options[:omission].length
        chars = text
        (chars.length > options[:length] ? chars[0...len] + options[:omission] : text).to_s
      end
    end

  end
end
