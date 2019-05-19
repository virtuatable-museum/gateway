require 'bundler'
Bundler.require(ENV['RACK_ENV'].to_sym || :development)
require 'sinatra/custom_logger'

$stdout.sync = true

Dotenv.load

Mongoid.load!(File.join(File.dirname(__FILE__), 'config', 'mongoid.yml'))

require './controllers/default.rb'
require './controllers/micro_service.rb'
require './utils/seeder.rb'

Utils::Seeder.instance.create_gateway

Arkaan::Monitoring::Service.each do |service|
  map(service.path) { run Controllers::MicroService.build_from(service) }
end

map('/') { run Controllers::Default.new }