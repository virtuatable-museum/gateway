ENV['GATEWAY_TOKEN'] = 'test_token'
ENV['GATEWAY_URL'] = 'https://gateway.com/'

RSpec.describe Controllers::MicroService do
  let!(:service) { create(:service) }
  let!(:application) { create(:application) }
  let!(:gateway) { create(:gateway) }

  def app
    Controllers::MicroService.build_from(service)
  end

  describe 'routes' do
    describe 'GET route without parameters' do
      describe 'Nominal case' do
        before do
          stub_request(:get, "https://service.com/test/first?app_key=test_key&token=test_token")
            .to_return(status: 200, body: {message: 'list'}.to_json, headers: {})

          get '/first', {app_key: application.key}
        end
        it 'returns a correct error code for a GET request without parameters' do
          expect(last_response.status).to be 200
        end
        it 'returns the correct body for a GET request without parameters' do
          expect(last_response.body).to eq({message: 'list'}.to_json)
        end
      end
      describe 'No application key error' do
        before do
          get '/first'
        end
        it 'returns a Bad Request (400) error code when no application key is given' do
          expect(last_response.status).to be 400
        end
        it 'returns the correct body when the application key is not given' do
          expect(last_response.body).to eq({message: 'bad_request'}.to_json)
        end
      end
      describe 'Unknown application error' do
        before do
          get '/first', {app_key: 'any unknown key'}
        end
        it 'returns a Not Found (404) error code when no application key is given' do
          expect(last_response.status).to be 404
        end
        it 'returns the correct body when the application key is not given' do
          expect(last_response.body).to eq({message: 'application_not_found'}.to_json)
        end
      end
    end
    describe 'GET route with parameters' do
      describe 'Nominal case' do
        before do
          stub_request(:get, "https://service.com/test/second/1?app_key=test_key&token=test_token")
            .to_return(status: 200, body: {message: 'item'}.to_json, headers: {})

          get '/second/1', {app_key: application.key}
        end
        it 'returns a correct error code for a GET request with parameters' do
          expect(last_response.status).to be 200
        end
        it 'returns the correct body for a GET request with parameters' do
          expect(last_response.body).to eq({message: 'item'}.to_json)
        end
      end
      describe 'No application key error' do
        before do
          get '/second/1'
        end
        it 'returns a Bad Request (400) error code when no application key is given' do
          expect(last_response.status).to be 400
        end
        it 'returns the correct body when the application key is not given' do
          expect(last_response.body).to eq({message: 'bad_request'}.to_json)
        end
      end
      describe 'Unknown application error' do
        before do
          get '/second/1', {app_key: 'any unknown key'}
        end
        it 'returns a Not Found (404) error code when no application key is given' do
          expect(last_response.status).to be 404
        end
        it 'returns the correct body when the application key is not given' do
          expect(last_response.body).to eq({message: 'application_not_found'}.to_json)
        end
      end
    end
    describe 'POST route without parameters' do
      describe 'Nominal case' do
        before do
          stub_request(:post, "https://service.com/test/third")
            .with(
              body: {
                app_key: 'test_key', token: 'test_token'
              },
              headers: {
                'Content-Type' => 'application/json'
              }
            )
            .to_return(status: 201, body: {message: 'created'}.to_json, headers: {})

          post '/third', {app_key: application.key}.to_json
        end
        it 'returns a correct error code for a POST request without parameters' do
          expect(last_response.status).to be 201
        end
        it 'returns the correct body for a POST request without parameters' do
          expect(last_response.body).to eq({message: 'created'}.to_json)
        end
      end
      describe 'No application key error' do
        before do
          post '/third'
        end
        it 'returns a Bad Request (400) error code when no application key is given' do
          expect(last_response.status).to be 400
        end
        it 'returns the correct body when the application key is not given' do
          expect(last_response.body).to eq({message: 'bad_request'}.to_json)
        end
      end
      describe 'Unknown application error' do
        before do
          post '/third', {app_key: 'any unknown key'}.to_json
        end
        it 'returns a Not Found (404) error code when no application key is given' do
          expect(last_response.status).to be 404
        end
        it 'returns the correct body when the application key is not given' do
          expect(last_response.body).to eq({message: 'application_not_found'}.to_json)
        end
      end
    end
    describe 'PUT route with parameters' do
      describe 'Nominal case' do
        before do
          stub_request(:put, "https://service.com/test/fourth/1")
            .with(
              body: {
                app_key: 'test_key', token: 'test_token'
              },
              headers: {
                'Content-Type' => 'application/json'
              }
            )
            .to_return(status: 200, body: {message: 'updated'}.to_json, headers: {})

          put '/fourth/1', {app_key: application.key}.to_json
        end
        it 'returns a correct error code for a PUT request with parameters' do
          expect(last_response.status).to be 200
        end
        it 'returns the correct body for a PUT request with parameters' do
          expect(last_response.body).to eq({message: 'updated'}.to_json)
        end
      end
      describe 'No application key error' do
        before do
          put '/fourth/1'
        end
        it 'returns a Bad Request (400) error code when no application key is given' do
          expect(last_response.status).to be 400
        end
        it 'returns the correct body when the application key is not given' do
          expect(last_response.body).to eq({message: 'bad_request'}.to_json)
        end
      end
      describe 'Unknown application error' do
        before do
          put '/fourth/1', {app_key: 'any unknown key'}.to_json
        end
        it 'returns a Not Found (404) error code when no application key is given' do
          expect(last_response.status).to be 404
        end
        it 'returns the correct body when the application key is not given' do
          expect(last_response.body).to eq({message: 'application_not_found'}.to_json)
        end
      end
    end
    describe 'DELETE route with parameters' do
      describe 'Nominal case' do
        before do
          stub_request(:delete, "https://service.com/test/fifth/1?app_key=test_key&token=test_token")
            .to_return(status: 200, body: {message: 'item'}.to_json)

          delete '/fifth/1', {app_key: application.key}
        end
        it 'returns a correct error code for a DELETE request with parameters' do
          expect(last_response.status).to be 200
        end
        it 'returns the correct body for a DELETE request with parameters' do
          expect(last_response.body).to eq({message: 'item'}.to_json)
        end
      end
      describe 'No application key error' do
        before do
          delete '/fifth/1'
        end
        it 'returns a Bad Request (400) error code when no application key is given' do
          expect(last_response.status).to be 400
        end
        it 'returns the correct body when the application key is not given' do
          expect(last_response.body).to eq({message: 'bad_request'}.to_json)
        end
      end
      describe 'Unknown application error' do
        before do
          delete '/fifth/1', {app_key: 'any unknown key'}
        end
        it 'returns a Not Found (404) error code when no application key is given' do
          expect(last_response.status).to be 404
        end
        it 'returns the correct body when the application key is not given' do
          expect(last_response.body).to eq({message: 'application_not_found'}.to_json)
        end
      end
    end
  end
end