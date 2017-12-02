module Utils
  # This class creates the gateway in the database if it does not exist yet.
  # @author Vincent Courtois <courtois.vincent@outlook.com>
  class Seeder
    include Singleton

    # Creates the gateway if it doesn't exist yet, or return it if it exists.
    # @return [Arkaan::Monitoring::Gateway] the gateway corresponding to this application.
    def create_gateway
      gateway = Arkaan::Monitoring::Gateway.where(url: ENV['GATEWAY_URL']).first
      if gateway.nil?
        gateway = Arkaan::Monitoring::Gateway.create!(url: ENV['GATEWAY_URL'], running: true, token: ENV['GATEWAY_TOKEN'])
      end
      return gateway
    end
  end
end