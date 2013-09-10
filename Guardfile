#!/usr/bin/env ruby

ENV['VISAGE_DATA_BACKEND'] = 'Mock'

## Reload the development server
#guard 'rack', :port => 9292, :config => 'lib/visage-app/config.ru', :server => 'puma', :force_run => true do
#  watch('Gemfile.lock')
#  watch(%r{^(lib)/.*})
#end

## Rebuild man pages
#guard 'ronn' do
#  watch(%r{^man/.+\.ronn$})
#end

# Recompile the coffeescript
guard 'rake', :task => 'coffee:compile' do
  watch(%r{lib/visage-app/assets/coffeescripts/(.+\.coffee)})
end
