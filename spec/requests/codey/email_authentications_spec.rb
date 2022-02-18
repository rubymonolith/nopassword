require 'rails_helper'

RSpec.describe "Codey::EmailAuthentications", type: :request do
  let(:email) { "somebody@example.com" }
  let(:email_authentication) { Codey::EmailAuthentication.new(email: email) }
  let!(:verification) { email_authentication.verification }
  let(:code) { email_authentication.code }
  subject { response }

  describe "POST /create" do
    let(:params) do
      { email: email }
    end

    context "valid params" do
      before { post "/email_authentication", params: { codey_email_authentication: params } }
      it { is_expected.to be_ok }
    end
  end

  describe "PATCH /update" do
    # Eagerly load this so the Verification objects have a secret to work from in the database.
    let!(:code) { email_authentication.code }
    let(:params) do
      {
        data: email,
        code: code,
        salt: verification.salt
      }
    end
    context "valid params" do
      before { patch "/email_authentication", params: { codey_verification: params } }
      it { is_expected.to redirect_to(root_url) }
    end
    context "3 invalid codes" do
      before do
        3.times do
          patch "/email_authentication", params: { codey_verification: params.merge(code: "invalid") }
        end
      end
      it { is_expected.to redirect_to(new_email_authentication_url) }
    end
    context "2 invalid codes, 1 valid code" do
      before do
        2.times do
          patch "/email_authentication", params: { codey_verification: params.merge(code: "invalid") }
        end
        patch "/email_authentication", params: { codey_verification: params }
      end
      it { is_expected.to redirect_to(root_url) }
    end
  end

  describe "GET /show" do
    before { get "/email_authentication" }
    it { is_expected.to redirect_to(new_email_authentication_url) }
  end
end
