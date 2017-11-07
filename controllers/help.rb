module Controllers
  class Help < Sinatra::Base
    get '/' do
      "Ici bientôt de l'aide pour utiliser l'API. [#{ENV['MONGODB_URI']}]"
    end
  end
end