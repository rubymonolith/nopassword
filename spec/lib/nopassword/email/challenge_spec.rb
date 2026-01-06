require "rails_helper"

RSpec.describe NoPassword::Email::Challenge do
  let(:session) { {} }
  let(:email) { "user@example.com" }
  let(:challenge) { described_class.new(session, identifier: email) }
  subject { challenge }

  describe "#email" do
    it "returns the identifier" do
      expect(challenge.email).to eq(email)
    end
  end

  describe "#email=" do
    it "sets the identifier" do
      challenge.email = "new@example.com"
      expect(challenge.identifier).to eq("new@example.com")
    end
  end

  it "inherits from Link::Challenge" do
    expect(described_class).to be < NoPassword::Link::Challenge
  end
end
