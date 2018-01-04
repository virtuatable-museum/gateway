RSpec.describe Controllers::Default do

  def app
    Controllers::Default.new
  end

  describe 'GET request' do
    before do
      get '/anything'
    end
    it 'Returns a 404 error code when the default GET route is called' do
      expect(last_response.status).to be 404
    end
    it 'Returns the correct body when the default GET route is called' do
      expect(last_response.body).to eq({message: 'path_not_found'}.to_json)
    end
  end
  describe 'POST request' do
    before do
      post '/anything'
    end
    it 'Returns a 404 error code when the default POST route is called' do
      expect(last_response.status).to be 404
    end
    it 'Returns the correct body when the default POST route is called' do
      expect(last_response.body).to eq({message: 'path_not_found'}.to_json)
    end
  end
  describe 'PUT request' do
    before do
      put '/anything'
    end
    it 'Returns a 404 error code when the default PUT route is called' do
      expect(last_response.status).to be 404
    end
    it 'Returns the correct body when the default PUT route is called' do
      expect(last_response.body).to eq({message: 'path_not_found'}.to_json)
    end
  end
  describe 'DELETE request' do
    before do
      delete '/anything'
    end
    it 'Returns a 404 error code when the default DELETE route is called' do
      expect(last_response.status).to be 404
    end
    it 'Returns the correct body when the default DELETE route is called' do
      expect(last_response.body).to eq({message: 'path_not_found'}.to_json)
    end
  end
end