source 'https://rubygems.org'

group :development, :production, :test do
  gem 'sinatra'        , '3.0.4', require: 'sinatra/base'
  gem 'sinatra-contrib', '3.0.4'
  gem 'mongoid'        , '7.0.1'
  gem 'arkaan'         , '2.7.1'
  gem 'draper'         , '3.0.1'
  gem 'faraday'        , '0.15.2'
  gem 'pry'            , '0.11.1'

  gem 'capistrano'        , '3.11.0'
  gem 'capistrano-bundler', '1.5.0'
  gem 'capistrano-rvm'    , '0.1.1'
  gem 'dotenv', '2.7.2'
end

group :test do
  gem 'rspec'
  gem 'factory_girl'
  gem 'database_cleaner'
  gem 'rack-test', require: 'rack/test'
  gem 'simplecov'
  gem 'webmock', require: 'webmock/rspec'
  gem 'rspec-json_expectations'
end