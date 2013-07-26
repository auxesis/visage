#!/usr/bin/env ruby

@root = Pathname.new(File.dirname(__FILE__)).parent.parent.parent.expand_path
require @root.join('lib/visage-app/config')
require 'yaml'

YAML::ENGINE.yamler = 'syck'

module Visage
  class Config
    class File
      @@config_directories = []
      @@config_directories << Pathname.new(::File.dirname(__FILE__)).expand_path
      @@config_directories << Pathname.new(ENV["CONFIG_PATH"]).expand_path if ENV["CONFIG_PATH"]
      @@config_directories.reverse!

      def self.find(filename, opts={})
        range = opts[:ignore_bundled] ? (0..-2) : (0..-1)
        potential_filenames = @@config_directories[range].map {|d| d.join(filename)}
        potential_filenames.find { |f| ::File.exists?(f) }
      end

      def self.load(filename, opts={})
        if not path = self.find(filename, opts)
          if opts[:create]
            path = @@config_directories.first.join(filename)
            begin
              FileUtils.touch(path)
              ::File.open(path, 'w') do |f|
                f << { :meta => {:version => "3.0.0"}}.to_yaml
              end
            rescue Errno::EACCES => e
              raise Errno::EACCES, "Couldn't write #{path}. Do you have CONFIG_PATH set?"
            end
          end
        end

        YAML::load_file(path)
      end

      def self.open(filename, &block)
        path = self.find(filename)
        ::File.open(path, 'r+') do |f|
          block.call(f)
        end
      end

      def initialize(filename, opts={})
        if not ::File.exists?(filename)
          path = @@config_directories.first.join(filename)
          FileUtils.touch(path)
        end
        @file = ::File.open(filename, 'r+')
      end

      def to_s
        @file.path
      end
    end
  end
end

