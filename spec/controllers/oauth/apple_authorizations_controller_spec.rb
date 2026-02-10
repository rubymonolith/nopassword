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
      expect(url.to_s).to include("nonce=")
    end

    it "generates and stores nonce in session" do
      controller.send(:authorization_url)
      expect(session[:apple_oauth_nonce]).to be_present
      expect(session[:apple_oauth_nonce].length).to eq(32)
    end
  end

  describe "validate_state_token" do
    it "raises on invalid state token" do
      allow(controller).to receive(:params).and_return(ActionController::Parameters.new(state: "invalid"))

      expect {
        controller.send(:validate_state_token)
      }.to raise_error(ActionController::InvalidAuthenticityToken)
    end

    it "passes with valid state token" do
      token = controller.send(:form_authenticity_token)
      allow(controller).to receive(:params).and_return(ActionController::Parameters.new(state: token))

      expect {
        controller.send(:validate_state_token)
      }.not_to raise_error
    end
  end

  describe "generate_nonce" do
    it "generates a 32-character token" do
      nonce = controller.send(:generate_nonce)
      expect(nonce.length).to eq(32)
    end

    it "stores nonce in session" do
      nonce = controller.send(:generate_nonce)
      expect(session[:apple_oauth_nonce]).to eq(nonce)
    end

    it "generates unique nonces" do
      nonces = 10.times.map { controller.send(:generate_nonce) }
      expect(nonces.uniq.length).to eq(10)
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
