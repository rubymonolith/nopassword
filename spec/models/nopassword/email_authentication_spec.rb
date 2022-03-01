require 'rails_helper'

RSpec.describe NoPassword::EmailAuthentication, type: :model do
  let(:email) { "brad@example.com" }
  let(:authentication) { NoPassword::EmailAuthentication.new(email: email) }
  subject { authentication }

  it { is_expected.to be_valid }

  describe "#secret" do
    subject { authentication.code }
    it "has a 6 digit code" do
      expect(subject.length).to be 6
    end
  end

  describe "#email" do
    context "invalid" do
      let(:email) { "not-an-email" }
      it { is_expected.to_not be_valid }
    end
  end

  describe "#verification" do
    subject { authentication.verification }
    it "has sufficiently long salt" do
      expect(subject.salt.length).to be > 32
    end
    it "has nil code" do
      # If this has a code, it creates a security risk by distrubting
      # the code with the other side of the secret.
      expect(subject.code).to be_nil
    end
    it "has data" do
      expect(subject.data).to eql email
    end
  end
end
