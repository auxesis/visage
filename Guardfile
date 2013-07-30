#!/usr/bin/env ruby

ENV['VISAGE_DATA_BACKEND'] = 'Mock'

guard 'rack', :port => 9292, :config => 'lib/visage-app/config.ru', :server => 'puma' do
  watch('Gemfile.lock')
  watch(%r{^(lib)/.*})
end

guard 'ronn' do
  watch(%r{^man/.+\.ronn$})
end
