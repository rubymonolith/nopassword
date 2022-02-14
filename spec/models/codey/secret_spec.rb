require 'rails_helper'

RSpec.describe Codey::Secret, type: :model do
  let(:data) { "brad@example.com" }
  let(:code) { "123456" }
  subject { Codey::Secret.new(data: data, code: code) }

  context "new secret" do
    it "persists" do
      expect(subject.save!)
    end
  end

  context "existing secret" do
    let(:secret) { Codey::Secret.new(data: data, code: code) }
    subject { Codey::Secret.find_by_salt! secret.salt }
    before { secret.save! }

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

  describe "#has_expired?" do
    before { subject.save! }
    context "within time to live" do
      it { is_expected.to_not have_expired }
    end
    context "after time to live" do
      before { travel_to 6.minutes.from_now }
      it { is_expected.to have_expired }
      it { is_expected.not_to be_valid }
      after { travel_back }
    end
  end

  describe "#verification_attempts" do
    subject { Codey::Secret.new(data: data, code: code, remaining_attempts: remaining_attempts) }
    describe "valid with 1 remaining attempt" do
      let(:remaining_attempts) { 1 }
      it { is_expected.to be_valid }
    end
    describe "invalid with 0 remaining attempts" do
      let(:remaining_attempts) { 0 }
      it { is_expected.to_not be_valid }
    end
    describe "decrypting past maximum remaining attempts" do
      let(:remaining_attempts) { 0 }
      it "raises exception" do
        subject.clear
        expect{subject.data}.to raise_error{ActiveSupport::MessageEncryptor::InvalidMessage}
      end
    end
  end
end
