require "rails_helper"

RSpec.describe NoPassword::Link::Challenge do
  let(:session) { {} }
  let(:identifier) { "user@example.com" }
  let(:challenge) { described_class.new(session, identifier:) }
  subject { challenge }

  describe "attributes" do
    it { is_expected.to respond_to(:identifier) }
    it { is_expected.to respond_to(:token) }
    it { is_expected.to respond_to(:created_at) }
    it { is_expected.to respond_to(:ttl) }
  end

  describe "validations" do
    it { is_expected.to be_valid }

    context "without identifier" do
      let(:identifier) { nil }
      it { is_expected.not_to be_valid }
    end
  end

  describe "#save" do
    it "generates a token" do
      expect { challenge.save }.to change { challenge.token }.from(nil)
    end

    it "generates a 32-character hex token (128 bits)" do
      challenge.save
      expect(challenge.token).to match(/\A[a-f0-9]{32}\z/)
    end

    it "sets created_at" do
      freeze_time do
        challenge.save
        expect(challenge.created_at).to eq(Time.current)
      end
    end

    it "stores the challenge in the session" do
      challenge.save
      expect(session[:nopassword_challenge]).to include(
        "identifier" => identifier,
        "token" => challenge.token
      )
    end

    it "returns true on success" do
      expect(challenge.save).to be true
    end

    context "when invalid" do
      let(:identifier) { nil }

      it "returns false" do
        expect(challenge.save).to be false
      end

      it "does not generate a token" do
        challenge.save
        expect(challenge.token).to be_nil
      end
    end
  end

  describe "#expires_at" do
    before { freeze_time }
    after { unfreeze_time }

    it "returns nil before save" do
      expect(challenge.expires_at).to be_nil
    end

    it "returns created_at + ttl after save" do
      challenge.save
      expect(challenge.expires_at).to eq(Time.current + challenge.ttl.seconds)
    end
  end

  describe "#delete" do
    before { challenge.save }

    it "removes the challenge from the session" do
      challenge.delete
      expect(session[:nopassword_challenge]).to be_nil
    end
  end

  describe "default TTL" do
    it "defaults to 10 minutes" do
      expect(challenge.ttl).to eq(10.minutes.to_i)
    end
  end

  describe "loading from session" do
    before { challenge.save }

    it "loads existing data from session" do
      loaded = described_class.new(session)
      expect(loaded.identifier).to eq(identifier)
      expect(loaded.token).to eq(challenge.token)
    end
  end
end
