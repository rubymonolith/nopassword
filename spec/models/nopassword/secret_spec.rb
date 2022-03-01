require 'rails_helper'

RSpec.describe NoPassword::Secret, type: :model do
  let(:data) { "brad@example.com" }
  let(:code) { "123456" }
  let(:remaining_attempts) { NoPassword::Secret::DEFAULT_REMAINING_ATTEMPTS }
  let(:secret) { NoPassword::Secret.new(data: data, code: code, remaining_attempts: remaining_attempts) }
  let(:salt) { secret.salt }
  subject { secret }

  it { is_expected.to be_valid }

  describe "#has_tampered_data?" do
    it { is_expected.to_not have_tampered_data }
    context "after_save" do
      before { secret.save! }
      it { is_expected.to_not have_tampered_data }
    end
    context "tampered data" do
      before { secret.save! }
      before { secret.data = "tampered!" }
      it { is_expected.to have_tampered_data }
    end
  end

  describe "#has_expired?" do
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

  describe "#verification_attempts" do
    describe "valid with 1 remaining attempt" do
      let(:remaining_attempts) { 1 }
      it { is_expected.to be_valid }
    end
    describe "invalid with 0 remaining attempts" do
      let(:remaining_attempts) { 0 }
      it { is_expected.to_not be_valid }
    end
    describe "invalid with -1 remaining attempts" do
      let(:remaining_attempts) { -1 }
      it { is_expected.to_not be_valid }
    end
  end

  context "persisted" do
    before { secret.save! }
    subject { NoPassword::Secret.find_by_digest salt: secret.salt, data: data }

    describe "#code" do
      before { subject.code = code }
      it { is_expected.to be_valid }
      it { is_expected.to have_authentic_code }
      context "incorrect" do
        before { subject.code = "incorrect" }
        it { is_expected.to_not be_valid }
        it { is_expected.to_not have_authentic_code }
      end
    end
  end
end
