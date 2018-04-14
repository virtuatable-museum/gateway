ENV['GATEWAY_TOKEN'] = 'test_token'
ENV['GATEWAY_URL'] = 'https://gateway.com/'

RSpec.describe Controllers::MicroService do
  let!(:application) { create(:application) }
  let!(:gateway) { create(:gateway) }
  let!(:account) { create(:account) }
  let!(:valid_session) {
    tmp_session = create(:valid_session, account: account)
    account.sessions << tmp_session
    account.save!
    tmp_session
  }
  let!(:invalid_session) { 
    tmp_session = create(:invalid_session, account: account)
    account.sessions << tmp_session
    account.save!
    tmp_session
  }

  describe 'when everything is active' do
    let!(:service) { create(:service) }

    def app
      Controllers::MicroService.build_from(service)
    end
    describe 'routes' do
      describe 'GET route without parameters' do
        include_examples 'route', 'get', '/first'
      end
      describe 'GET route with parameters' do
        include_examples 'route', 'get', '/second/1'
      end
      describe 'POST route without parameters' do
        include_examples 'route', 'post', '/third'
      end
      describe 'PUT route with parameters' do
        include_examples 'route', 'put', '/fourth/1'
      end
      describe 'DELETE route with parameters' do
        include_examples 'route', 'delete', '/fifth/1'
      end
    end
  end

  describe 'when something is inactive' do
    describe 'when the service is inactive' do
      let!(:service) { create(:inactive_service) }

      def app
        Controllers::MicroService.build_from(service)
      end

      before do
        get '/first', {app_key: application.key}
      end
      it 'returns a Bad Request (400) status code when the whole service is inactive' do
        expect(last_response.status).to be 400
      end
      it 'returns the correct body when the whole service is inactive' do
        expect(JSON.parse(last_response.body)).to include_json({
          'status' => 400,
          'field' => 'service',
          'error' => 'inactive'
        })
      end
    end
    describe 'when all the instances are inactive' do
      def app
        Controllers::MicroService.build_from(create(:service_with_inactive_instance))
      end
      
      before do
        get '/first', {app_key: application.key}
      end
      it 'returns a Bad Request (400) status code when all instances are inactive' do
        expect(last_response.status).to be 400
      end
      it 'returns the correct body when all instances are inactive' do
        expect(JSON.parse(last_response.body)).to include_json({
          'status' => 400,
          'field' => 'instance',
          'error' => 'unavailable'
        })
      end
    end
    describe 'when the route is inactive' do
      def app
        Controllers::MicroService.build_from(create(:service_with_inactive_route))
      end
      
      before do
        get '/first', {app_key: application.key}
      end
      it 'returns a Bad Request (400) status code when the route is inactive' do
        expect(last_response.status).to be 400
      end
      it 'returns the correct body when the route is inactive' do
        expect(JSON.parse(last_response.body)).to include_json({
          'status' => 400,
          'field' => 'route',
          'error' => 'inactive'
        })
      end
    end
  end
end