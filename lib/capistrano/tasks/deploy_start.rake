namespace :deploy do
  desc 'Stops the server'
  task :stop do
    on roles(:all) do
      within current_path do
        pid_file = "/tmp/#{fetch(:application)}.pid"
        if test("[ -f #{pid_file}.pid ]")
          puts 'Le fichier du PID a bien été trouvé et va être supprimé.'
          execute :kill, "-9 `cat #{pid_file}.pid`"
        else
          puts "Le fichier du PID n'a pas été trouvé et ne peux pas être supprimé."
        end
      end
    end
  end

  desc 'Starts the server'
  task :start => 'stop' do
    pid_file = "/tmp/#{fetch(:application)}.pid"
    execute :bundle, "exec rackup -p #{fetch(:app_port)} --env production -o 0.0.0.0 -P #{pid_file} --daemonize"
  end

  after :finishing, :start
end