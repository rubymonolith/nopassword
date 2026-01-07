require "rails_helper"

RSpec.describe "Security" do
  describe "token generation" do
    it "uses SecureRandom" do
      expect(SecureRandom).to receive(:hex).with(16).and_call_original
      challenge = NoPassword::Link::Challenge.new({}, identifier: "test@example.com")
      challenge.save
    end

    it "generates 128 bits of entropy (32 hex chars)" do
      challenge = NoPassword::Link::Challenge.new({}, identifier: "test@example.com")
      challenge.save
      expect(challenge.token.length).to eq(32)
      expect(challenge.token).to match(/\A[a-f0-9]{32}\z/)
    end

    it "generates unique tokens" do
      tokens = 100.times.map do
        challenge = NoPassword::Link::Challenge.new({}, identifier: "test@example.com")
        challenge.save
        challenge.token
      end
      expect(tokens.uniq.length).to eq(100)
    end
  end

  describe "token comparison" do
    it "uses constant-time comparison" do
      expect(ActiveSupport::SecurityUtils).to receive(:secure_compare).and_call_original
      session = {}
      challenge = NoPassword::Link::Challenge.new(session, identifier: "test@example.com")
      challenge.save
      verification = NoPassword::Link::Verification.new(challenge:, provided_token: challenge.token)
      verification.verify
    end
  end

  describe "token expiration" do
    it "expires after TTL" do
      session = {}
      challenge = NoPassword::Link::Challenge.new(session, identifier: "test@example.com", ttl: 1)
      challenge.save

      travel 2.seconds do
        verification = NoPassword::Link::Verification.new(challenge: NoPassword::Link::Challenge.new(session), provided_token: challenge.token)
        expect(verification.verify).to be false
        expect(verification.errors[:base]).to include("Link has expired. Please request a new one.")
      end
    end
  end
end
