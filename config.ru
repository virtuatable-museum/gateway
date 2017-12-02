require 'bundler'
Bundler.require(ENV['RACK_ENV'].to_sym || :development)

Mongoid.load!(File.join(File.dirname(__FILE__), 'config', 'mongoid.yml'))

require './controllers/service.rb'
require './utils/seeder.rb'

Utils::Seeder.instance.create_gateway

Arkaan::Monitoring::Service.each do |service|
  map(service.path) { run Controllers::Service.new(service) }
end