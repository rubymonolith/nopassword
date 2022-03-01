require 'rails_helper'

RSpec.describe NoPassword::Verification, type: :model do
  let(:email) { "brad@example.com" }
  let(:authentication) { NoPassword::EmailAuthentication.new(email: email) }
  let(:code) { authentication.code }
  let(:salt) { authentication.verification.salt }
  let(:verification) { NoPassword::Verification.new(code: code, salt: salt, data: email) }
  subject { verification }

  it { is_expected.to be_valid }

  describe "#code" do
    context "invalid" do
      let(:code) { "invalid" }
      it { is_expected.to be_invalid }
    end
    context "nil" do
      let(:code) { nil }
      it { is_expected.to be_invalid }
    end
  end

  describe "#salt" do
    describe "invalid" do
      let(:salt) { "invalid" }
      it { is_expected.to be_invalid }
    end
    context "nil" do
      let(:salt) { nil }
      it { is_expected.to be_invalid }
    end
  end

  describe "#data" do
    context "tampered" do
      before { verification.data = "tampered" }
      it { is_expected.to be_invalid }
    end
    context "nil" do
      before { verification.data = nil }
      it { is_expected.to be_invalid }
    end
  end

  describe "#code_verification_attempts" do
    it { is_expected.to_not have_exceeded_attempts }
    context "exceeded" do
      let(:code) { "wrong code" }
      before do
        3.times { verification.valid? }
      end
      it { is_expected.to have_exceeded_attempts }
    end
  end

  describe "#code_expiration" do
    before { freeze_time }
    it { is_expected.to_not have_expired }
    context "after expires_at" do
      let(:expired_time) { subject.expires_at + 1.second }
      before { travel_to expired_time }
      it { is_expected.to have_expired }
      it { is_expected.not_to be_valid }
    end
    after { unfreeze_time }
  end
end
