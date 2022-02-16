require 'rails_helper'

RSpec.describe Codey::Verification, type: :model do
  let(:email) { "brad@example.com" }
  let(:authentication) { Codey::EmailAuthentication.new(email: email) }
  let(:code) { authentication.code }
  let(:salt) { authentication.verification.salt }
  let(:verification) { Codey::Verification.new(code: code, salt: salt) }
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

  describe "#code_verification_attempts" do
    it { is_expected.to have_remaining_attempts }
    context "exceeded" do
      let(:code) { "wrong code" }
      let(:attempts) { verification.remaining_attempts }
      before do
        attempts.times { verification.valid? }
      end
      it { is_expected.to_not have_remaining_attempts }
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

  describe "#data" do
    let(:subject) { verification.data }
    it { is_expected.to eql email }
    context "invalid" do
      before { allow(verification).to receive(:valid?).and_return(false)  }
      it { is_expected.to be_nil }
    end
  end
end
