require 'digest/sha1'

# DO NOT MODIFY THIS FILE
module Bundler
  FINGERPRINT = "5a3963622ba6a29ae03234b6c80ea0cfa1dae3bf"
  LOAD_PATHS = ["/home/auxesis/code/visage/vendor/gems/gems/nokogiri-1.4.1/lib", "/home/auxesis/code/visage/vendor/gems/gems/nokogiri-1.4.1/ext", "/home/auxesis/code/visage/vendor/gems/gems/yajl-ruby-0.7.0/lib", "/home/auxesis/code/visage/vendor/gems/gems/yajl-ruby-0.7.0/ext", "/home/auxesis/code/visage/vendor/gems/gems/builder-2.1.2/lib", "/home/auxesis/code/visage/vendor/gems/gems/json_pure-1.2.0/lib", "/home/auxesis/code/visage/vendor/gems/gems/rack-1.1.0/lib", "/home/auxesis/code/visage/vendor/gems/gems/rack-test-0.5.3/lib", "/home/auxesis/code/visage/vendor/gems/gems/sinatra-0.9.4/lib", "/home/auxesis/code/visage/vendor/gems/gems/webrat-0.7.0/lib", "/home/auxesis/code/visage/vendor/gems/gems/polyglot-0.2.9/lib", "/home/auxesis/code/visage/vendor/gems/gems/treetop-1.4.3/lib", "/home/auxesis/code/visage/vendor/gems/gems/haml-2.2.19/lib", "/home/auxesis/code/visage/vendor/gems/gems/diff-lcs-1.1.2/lib", "/home/auxesis/code/visage/vendor/gems/gems/rspec-1.3.0/lib", "/home/auxesis/code/visage/vendor/gems/gems/term-ansicolor-1.0.4/lib", "/home/auxesis/code/visage/vendor/gems/gems/cucumber-0.6.2/lib", "/home/auxesis/code/visage/vendor/gems/gems/errand-0.7.0/lib"]
  AUTOREQUIRES = {:testing=>["cucumber", "rspec", "webrat", "rack-test"], :default=>["sinatra", "haml", "errand", "yajl-ruby"]}

  def self.match_fingerprint
    print = Digest::SHA1.hexdigest(File.read(File.expand_path('../../Gemfile', __FILE__)))
    unless print == FINGERPRINT
      abort 'Gemfile changed since you last locked. Please `bundle lock` to relock.'
    end
  end

  def self.setup(*groups)
    match_fingerprint
    LOAD_PATHS.each { |path| $LOAD_PATH.unshift path }
  end

  def self.require(*groups)
    groups = [:default] if groups.empty?
    groups.each do |group|
      (AUTOREQUIRES[group] || []).each { |file| Kernel.require file }
    end
  end

  # Setup bundle when it's required.
  setup
end
