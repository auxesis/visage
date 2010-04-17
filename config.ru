#!/usr/bin/env ruby

require 'pathname'

@root = Pathname.new(File.expand_path(File.join(File.dirname(__FILE__))))
require @root.join('vendor', 'gems', 'environment')

require 'visage'
run Sinatra::Application

