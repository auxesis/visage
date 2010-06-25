#!/usr/bin/env ruby

@root = Pathname.new(File.dirname(__FILE__)).parent.parent.expand_path
$: << @root.to_s

$0 = "visage"

require 'lib/visage-app'
run Sinatra::Application

