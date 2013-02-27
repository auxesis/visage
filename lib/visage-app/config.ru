#!/usr/bin/env ruby

require 'pathname'
@root = Pathname.new(File.dirname(__FILE__)).parent.parent.expand_path
$: << @root.to_s

$0 = "visage"

require 'lib/visage-app'
use Visage::Profiles
use Visage::JSON
run Sinatra::Base
