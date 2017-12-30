ENV['GATEWAY_URL'] = 'https://gateway.com/'
ENV['GATEWAY_TOKEN'] = 'test_token'

RSpec.describe Utils::Seeder do
  let!(:seeder) { Utils::Seeder.instance }

  describe :create_gateway do
    describe 'when the gateway does not already exist' do
      let!(:gateway) { seeder.create_gateway }

      it 'correctly creates a gateway' do
        expect(Arkaan::Monitoring::Gateway.all.count).to be 1
      end
      describe 'gateway parameters' do
        let!(:mongo_gateway) { Arkaan::Monitoring::Gateway.first }

        it 'creates a gateway with the correct url' do
          expect(mongo_gateway.url).to eq gateway.url
        end
        it 'creates a gateway with the correct token' do
          expect(mongo_gateway.token).to eq gateway.token
        end
        it 'creates a gateway running by default' do
          expect(mongo_gateway.running).to be gateway.running
        end
        it 'creates a gateway active by default' do
          expect(mongo_gateway.running).to be gateway.active
        end
        it 'creates a gateway with the default diagnostic url' do
          expect(mongo_gateway.diagnostic).to eq gateway.diagnostic
        end
      end
    end
    describe 'when the gateway already exists' do
      let!(:gateway) {
        create(:gateway)
        seeder.create_gateway
      }

      it 'does not create a new gateway after the first one has been created' do
        expect(Arkaan::Monitoring::Gateway.all.count).to be 1
      end
      describe 'gateway parameters' do
        let!(:mongo_gateway) { Arkaan::Monitoring::Gateway.first }

        it 'gets a gateway with the correct url' do
          expect(mongo_gateway.url).to eq gateway.url
        end
        it 'gets a gateway with the correct token' do
          expect(mongo_gateway.token).to eq gateway.token
        end
        it 'gets a gateway with the correct running flag' do
          expect(mongo_gateway.running).to be gateway.running
        end
        it 'gets a gateway with the correct active flag' do
          expect(mongo_gateway.running).to be gateway.active
        end
        it 'gets a gateway with the correct diagnostic url' do
          expect(mongo_gateway.diagnostic).to eq gateway.diagnostic
        end
      end
    end
  end
end