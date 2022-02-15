require 'rails_helper'

RSpec.describe Codey::Verification, type: :model do
  let(:email) { "brad@example.com" }
  let(:authentication) { Codey::EmailAuthentication.new(email: email) }
  let(:code) { authentication.code }
  let(:salt) { authentication.verification.salt }
  let(:verification) { Codey::Verification.new(code: code, salt: salt) }
  subject { verification }

  it { is_expected.to be_valid }

  describe "#data" do
    let(:subject) { verification.data }
    it { is_expected.to eql email }
    context "invalid" do
      before { allow(verification).to receive(:valid?).and_return(false)  }
      it { is_expected.to be_nil }
    end
  end

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
end
