require "rails_helper"

RSpec.describe NoPassword::OAuth::AppleAuthorizationsController, type: :controller do
  before do
    allow(controller).to receive(:callback_url).and_return("https://example.com/callback")
    described_class.define_singleton_method(:client_id) { "test-client-id" }
    described_class.define_singleton_method(:team_id) { "test-team-id" }
    described_class.define_singleton_method(:key_id) { "test-key-id" }
    described_class.define_singleton_method(:private_key) { "test-private-key" }
  end

  after do
    described_class.singleton_class.remove_method(:client_id) if described_class.respond_to?(:client_id)
    described_class.singleton_class.remove_method(:team_id) if described_class.respond_to?(:team_id)
    described_class.singleton_class.remove_method(:key_id) if described_class.respond_to?(:key_id)
    described_class.singleton_class.remove_method(:private_key) if described_class.respond_to?(:private_key)
  end

  describe "authorization_url" do
    it "includes required OAuth parameters" do
      url = controller.send(:authorization_url)
      expect(url.to_s).to include("appleid.apple.com")
      expect(url.to_s).to include("client_id=test-client-id")
      expect(url.to_s).to include("redirect_uri=")
      expect(url.to_s).to include("response_type=code")
      expect(url.to_s).to include("response_mode=form_post")
      expect(url.to_s).to include("scope=")
      expect(url.to_s).to include("state=")
    end

    it "generates and stores state token in session" do
      url = controller.send(:authorization_url)
      expect(session[:oauth_state_token]).to be_present
      expect(session[:oauth_state_token].length).to eq(32)
    end
  end

  describe "validate_state_token" do
    it "raises on invalid state token" do
      session[:oauth_state_token] = "a" * 32
      allow(controller).to receive(:params).and_return({ state: "b" * 32 })

      expect {
        controller.send(:validate_state_token)
      }.to raise_error(ActionController::InvalidAuthenticityToken)
    end

    it "passes with valid state token" do
      token = "a" * 32
      session[:oauth_state_token] = token
      allow(controller).to receive(:params).and_return({ state: token })

      expect {
        controller.send(:validate_state_token)
      }.not_to raise_error
    end
  end

  describe "generate_state_token" do
    it "generates a 32-character token" do
      token = controller.send(:generate_state_token)
      expect(token.length).to eq(32)
    end

    it "stores token in session" do
      token = controller.send(:generate_state_token)
      expect(session[:oauth_state_token]).to eq(token)
    end

    it "generates unique tokens" do
      tokens = 10.times.map { controller.send(:generate_state_token) }
      expect(tokens.uniq.length).to eq(10)
    end
  end

  describe "generate_client_secret" do
    before do
      # Generate a test EC key for specs
      test_key = OpenSSL::PKey::EC.generate("prime256v1")
      described_class.define_singleton_method(:private_key) { test_key.to_pem }
      described_class.define_singleton_method(:team_id) { "TEAM123" }
      described_class.define_singleton_method(:client_id) { "com.example.app" }
      described_class.define_singleton_method(:key_id) { "KEY123" }
    end

    it "generates a valid JWT" do
      secret = controller.send(:generate_client_secret)
      expect(secret).to be_present
      expect(secret.split(".").length).to eq(3) # JWT has 3 parts
    end
  end

  describe "authorization_failed" do
    it "raises NotImplementedError by default" do
      expect {
        controller.send(:authorization_failed)
      }.to raise_error(NotImplementedError, /Implement authorization_failed/)
    end
  end
end
