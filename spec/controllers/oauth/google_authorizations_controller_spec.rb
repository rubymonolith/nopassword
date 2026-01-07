require "rails_helper"

RSpec.describe NoPassword::OAuth::GoogleAuthorizationsController, type: :controller do
  before do
    allow(controller).to receive(:callback_url).and_return("https://example.com/callback")
  end

  describe "authorization_url" do
    it "includes required OAuth parameters" do
      url = controller.send(:authorization_url)
      expect(url.to_s).to include("accounts.google.com")
      expect(url.to_s).to include("client_id=")
      expect(url.to_s).to include("redirect_uri=")
      expect(url.to_s).to include("response_type=code")
      expect(url.to_s).to include("scope=")
      expect(url.to_s).to include("state=")
    end

    it "uses form_authenticity_token for state" do
      allow(controller).to receive(:form_authenticity_token).and_return("test-csrf-token")
      url = controller.send(:authorization_url)
      expect(url.to_s).to include("state=test-csrf-token")
    end
  end

  describe "validate_state_token" do
    it "raises on invalid state token" do
      allow(controller).to receive(:params).and_return({ state: "invalid-token" })
      allow(controller).to receive(:valid_authenticity_token?).and_return(false)

      expect {
        controller.send(:validate_state_token)
      }.to raise_error(ActionController::InvalidAuthenticityToken)
    end

    it "passes with valid state token" do
      allow(controller).to receive(:params).and_return({ state: "valid-token" })
      allow(controller).to receive(:valid_authenticity_token?).and_return(true)

      expect {
        controller.send(:validate_state_token)
      }.not_to raise_error
    end
  end

  describe "authorization_failed" do
    it "raises NotImplementedError by default" do
      expect {
        controller.send(:authorization_failed)
      }.to raise_error(NotImplementedError, /Implement authorization_failed/)
    end
  end

  describe "setting protection" do
    it "excludes settings from action_methods" do
      expect(described_class.action_methods).not_to include("client_id")
      expect(described_class.action_methods).not_to include("client_secret")
      expect(described_class.action_methods).not_to include("scope")
    end

    it "raises SettingExposedError if a setting is called as an action" do
      # Simulate someone accidentally making client_secret public and routing to it
      allow(controller).to receive(:action_name).and_return("client_secret")

      expect {
        controller.process_action("client_secret")
      }.to raise_error(NoPassword::OAuth::SettingExposedError, /client_secret/)
    end
  end
end
