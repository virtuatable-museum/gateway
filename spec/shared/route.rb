RSpec.shared_examples 'route' do |verb, path|

  # Formats the body so that it can be used in requests without considering the way of
  # transmitting parameters (querystring for GET/DELETE, JSON body otherwise).
  # @param verb [String] the verb used in the request.
  # @param raw_params [Hash] the hash of parameters to eventually format as a JSON string.
  def format_params(verb, raw_params)
    return ['get', 'delete'].include?(verb) ? raw_params : raw_params.to_json
  end

  # Stubs the request to the API for the nominal case scenario.
  # @param verb [String] the HTTP method used for this request.
  # @param path [String] the path for this request, with the first /
  def stub_api_request(verb, path)
    if ['get', 'delete'].include?(verb)
      stub_request(verb.to_sym, "https://service.com/test#{path}?app_key=test_key&session_id=#{valid_session.id.to_s}&token=test_token")
        .to_return(status: 200, body: {message: 'list'}.to_json, headers: {})
    else
      stub_request(verb.to_sym, "https://service.com/test#{path}")
        .with(
          body: {app_key: 'test_key', session_id: valid_session.id.to_s, token: 'test_token'}.to_json,
          headers: {'Content-Type' => 'application/json'})
        .to_return(status: 200, body: {message: 'list'}.to_json, headers: {})
    end
  end

  describe 'Nominal case' do
    let!(:group) {
      tmp_group = create(:group, routes: service.routes, accounts: [account])
      account.groups << tmp_group
      account.save
      service.routes.each do |route|
        route.groups << tmp_group
        route.save
      end
      tmp_group
    }
    before do
      stub_api_request(verb, path)
      request_body = {app_key: application.key, session_id: valid_session.id.to_s}
      public_send(verb.to_sym, path, ['get', 'delete'].include?(verb) ? request_body : request_body.to_json)
    end
    it 'returns a correct error code for this request with the right parameters' do
      expect(last_response.status).to be 200
    end
    it 'returns the correct body for this request with the right parameters' do
      expect(last_response.body).to eq({message: 'list'}.to_json)
    end
  end
  describe 'No application key error' do
    before do
      public_send(verb.to_sym, path, format_params(verb, {session_id: valid_session.id.to_s}))
    end
    it 'returns a Bad Request (400) error code when no application key is given' do
      expect(last_response.status).to be 400
    end
    it 'returns the correct body when the application key is not given' do
      expect(last_response.body).to eq({message: 'missing.app_key'}.to_json)
    end
  end
  describe 'No session identifier error' do
    before do
      public_send(verb.to_sym, path, format_params(verb, {app_key: application.key}))
    end
    it 'returns a Bad Request (400) error code when no session_id is given' do
      expect(last_response.status).to be 400
    end
    it 'returns the correct body when the session_id is not given' do
      expect(last_response.body).to eq({message: 'missing.session_id'}.to_json)
    end
  end
  describe 'Unknown application error' do
    before do
      public_send(verb.to_sym, path, format_params(verb, {app_key: 'any unknown key', session_id: valid_session.id.to_s}))
    end
    it 'returns a Not Found (404) error code when the application is not found' do
      expect(last_response.status).to be 404
    end
    it 'returns the correct body when the application is not found' do
      expect(last_response.body).to eq({message: 'application_not_found'}.to_json)
    end
  end
  describe 'Unknown session error' do
    before do
      public_send(verb.to_sym, path, format_params(verb, {app_key: application.key, session_id: 'any unknown id'}))
    end
    it 'returns a Not Found (404) error when the session is not found' do
      expect(last_response.status).to be 404
    end
    it 'returns the correct body when the session is not found' do
      expect(last_response.body).to eq({message: 'session_not_found'}.to_json)
    end
  end
  describe 'Invalid session error' do
    before do
      public_send(verb.to_sym, path, format_params(verb, {app_key: application.key, session_id: invalid_session.id.to_s}))
    end
    it 'returns an Unprocessable Entity (422) error when the session is invalid' do
      expect(last_response.status).to be 422
    end
    it 'returns the correct body when the session is invalid' do
      expect(last_response.body).to eq({message: 'invalid_session'}.to_json)
    end
  end
  describe 'Unauthorized error' do
    let!(:group) {
      tmp_group = create(:group, slug: 'another_group', accounts: [account])
      account.groups << tmp_group
      account.save
      tmp_group
    }
    before do
      public_send(verb.to_sym, path, format_params(verb, {app_key: application.key, session_id: valid_session.id.to_s}))
    end
    it 'returns an Unauthorized (401) error when the account has no right to access this route' do
      expect(last_response.status).to be 401
    end
    it 'returns the correct body when the account cannot access this route' do
      expect(last_response.body).to eq({message: 'unauthorized'}.to_json)
    end
  end
end