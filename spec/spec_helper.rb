require 'bundler'
Bundler.require :test

require File.join(File.dirname(__FILE__), '..', 'utils', 'seeder.rb')

Dir[File.join(File.dirname(__FILE__), 'support', '**', '*.rb')].each { |filename| require filename }