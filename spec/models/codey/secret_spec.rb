require 'rails_helper'

RSpec.describe Codey::Secret, type: :model do
  let(:data) { "brad@example.com" }
  let(:code) { "123456" }
  let(:remaining_attempts) { Codey::Secret::DEFAULT_REMAINING_ATTEMPTS }
  let(:secret) { Codey::Secret.new(data: data, code: code, remaining_attempts: remaining_attempts) }
  let(:salt) { secret.salt }
  subject { secret }

  it { is_expected.to be_valid }

  describe "#data" do
    subject { secret.data }
    context "after_save" do
      before { secret.save! }
      it { is_expected.to be_nil }
    end
  end

  describe "#encrypted_data" do
    subject { secret.encrypted_data }
    it { is_expected.to be_nil }
    context "after_save" do
      before { secret.save! }
      it { is_expected.to_not be_nil }
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

  context "persisted secret" do
    before { secret.save! }
    subject { Codey::Secret.find_by_salt! secret.salt }

    context "with correct code" do
      it "decrypts" do
        subject.code = secret.code
        expect(secret.data).to eql subject.data
      end
    end

    context "with incorrect code" do
      it "does not decrypt" do
        subject.code = "incorrect"
        expect{subject.data}.to raise_error{ActiveSupport::MessageEncryptor::InvalidMessage}
      end
    end
  end
end
