require "rails_helper"

RSpec.describe NoPassword::Link::Verification do
  let(:session) { {} }
  let(:identifier) { "user@example.com" }
  let(:challenge) { NoPassword::Link::Challenge.new(session, identifier:) }
  let(:provided_token) { challenge.token }
  let(:verification) { described_class.new(challenge: challenge, provided_token: provided_token) }
  subject { verification }

  before do
    freeze_time
    challenge.save
  end

  after { unfreeze_time }

  describe "#verify" do
    context "with valid token" do
      it "returns true" do
        expect(verification.verify).to be true
      end

      it "has no errors" do
        verification.verify
        expect(verification.errors).to be_empty
      end
    end

    context "with invalid token" do
      let(:provided_token) { "wrong_token" }

      it "returns false" do
        expect(verification.verify).to be false
      end

      it "has token error" do
        verification.verify
        expect(verification.errors[:token]).to include("is invalid")
      end
    end

    context "with blank token" do
      let(:provided_token) { "" }

      it "returns false" do
        expect(verification.verify).to be false
      end

      it "has base error" do
        verification.verify
        expect(verification.errors[:base]).to include("No token provided")
      end
    end

    context "with no challenge token" do
      let(:challenge) { NoPassword::Link::Challenge.new({}) }

      it "returns false" do
        expect(verification.verify).to be false
      end

      it "has base error about different browser" do
        verification.verify
        expect(verification.errors[:base].first).to include("same browser")
      end

      it "reports different_browser? as true" do
        expect(verification.different_browser?).to be true
      end

      it "reports missing_challenge? as true" do
        expect(verification.missing_challenge?).to be true
      end
    end

    context "when expired" do
      before { travel_to(11.minutes.from_now) }

      it "returns false" do
        expect(verification.verify).to be false
      end

      it "has expiration error" do
        verification.verify
        expect(verification.errors[:base]).to include("Link has expired. Please request a new one.")
      end
    end

    context "just before expiration" do
      before { travel_to(9.minutes.from_now) }

      it "returns true" do
        expect(verification.verify).to be true
      end
    end
  end

  describe "#expired?" do
    context "before expiration" do
      it "returns false" do
        expect(verification.expired?).to be false
      end
    end

    context "after expiration" do
      before { travel_to(11.minutes.from_now) }

      it "returns true" do
        expect(verification.expired?).to be true
      end
    end

    context "with no created_at" do
      let(:challenge) { NoPassword::Link::Challenge.new({}) }

      it "returns true" do
        expect(verification.expired?).to be true
      end
    end
  end

  describe "timing attack resistance" do
    it "uses secure_compare for token comparison" do
      expect(ActiveSupport::SecurityUtils).to receive(:secure_compare)
        .with(challenge.token.to_s, provided_token.to_s)
        .and_call_original

      verification.verify
    end
  end
end
