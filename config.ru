require 'bundler'
Bundler.require(ENV['RACK_ENV'].to_sym || :development)

Mongoid.load!(File.join(File.dirname(__FILE__), 'config', 'mongoid.yml'))

def require_absolute(filename)
  require 
end

require File.join(File.dirname(__FILE__), 'decorators', 'service.rb')
require File.join(File.dirname(__FILE__), 'controllers', 'service.rb')
require File.join(File.dirname(__FILE__), 'controllers', 'help.rb')

binding.pry

Arkaan::Monitoring::Service.each do |service|
  map(service.path) { run Controllers::Service.new(service) }
end


map('/') { run Controllers::Help.new }