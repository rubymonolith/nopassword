require "rails_helper"

RSpec.describe NoPassword::Email::Authentication do
  let(:session) { {} }
  let(:email) { "User@Example.COM" }
  let(:authentication) { described_class.new(session, email: email) }
  subject { authentication }

  describe "attributes" do
    it { is_expected.to respond_to(:email) }
    it { is_expected.to respond_to(:return_url) }
  end

  describe "email normalization" do
    it "strips whitespace" do
      auth = described_class.new(session, email: "  user@example.com  ")
      expect(auth.email).to eq("user@example.com")
    end

    it "downcases email" do
      auth = described_class.new(session, email: "USER@EXAMPLE.COM")
      expect(auth.email).to eq("user@example.com")
    end
  end

  describe "validations" do
    context "with valid email" do
      let(:email) { "user@example.com" }
      it { is_expected.to be_valid }
    end

    context "with invalid email" do
      let(:email) { "not-an-email" }
      it { is_expected.not_to be_valid }
    end

    context "with blank email" do
      let(:email) { "" }
      it { is_expected.not_to be_valid }
    end

    context "with nil email" do
      let(:email) { nil }
      it { is_expected.not_to be_valid }
    end
  end

  describe "#identifier" do
    it "returns the email" do
      expect(authentication.identifier).to eq(authentication.email)
    end
  end

  describe "#challenge" do
    it "returns an Email::Challenge" do
      expect(authentication.challenge).to be_a(NoPassword::Email::Challenge)
    end

    it "passes the email as identifier" do
      expect(authentication.challenge.identifier).to eq(authentication.email)
    end

    it "memoizes the challenge" do
      expect(authentication.challenge).to be(authentication.challenge)
    end
  end

  describe "#verification" do
    let(:token) { "test_token" }

    it "returns a Link::Verification" do
      expect(authentication.verification(token: token)).to be_a(NoPassword::Link::Verification)
    end

    it "passes the provided token" do
      verification = authentication.verification(token: token)
      expect(verification.provided_token).to eq(token)
    end
  end

  describe "#save" do
    it "stores the authentication in the session" do
      authentication.save
      expect(session[:nopassword_authentication]).to include("email" => authentication.email)
    end

    it "stores return_url if set" do
      authentication.return_url = "/dashboard"
      authentication.save
      expect(session[:nopassword_authentication]).to include("return_url" => "/dashboard")
    end
  end

  describe "#delete" do
    before do
      authentication.save
      authentication.challenge.save
    end

    it "removes the authentication from the session" do
      authentication.delete
      expect(session[:nopassword_authentication]).to be_nil
    end

    it "removes the challenge from the session" do
      authentication.delete
      expect(session[:nopassword_challenge]).to be_nil
    end
  end

  describe "loading from session" do
    before do
      authentication.return_url = "/dashboard"
      authentication.save
    end

    it "loads existing data from session" do
      loaded = described_class.new(session)
      expect(loaded.email).to eq(authentication.email)
      expect(loaded.return_url).to eq("/dashboard")
    end
  end
end
