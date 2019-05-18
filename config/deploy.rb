lock '~> 3.11.0'

set :application, 'virtuatable-gateway'
set :deploy_to, '/var/www/gateway'
set :repo_url, 'git@github.com:jdr-tools/gateway.git'
set :branch, 'master'

append :linked_files, 'config/mongoid.yml'
append :linked_files, '.env'
append :linked_dirs, 'bundle'