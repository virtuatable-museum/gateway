require 'bundler'
Bundler.require :test

require File.join(File.dirname(__FILE__), '..', 'utils', 'seeder.rb')
require File.join(File.dirname(__FILE__), '..', 'controllers', 'micro_service.rb')
require File.join(File.dirname(__FILE__), '..', 'controllers', 'default.rb')

Dir[File.join(File.dirname(__FILE__), 'shared', '**', '*.rb')].each { |filename| require filename }
Dir[File.join(File.dirname(__FILE__), 'support', '**', '*.rb')].each { |filename| require filename }