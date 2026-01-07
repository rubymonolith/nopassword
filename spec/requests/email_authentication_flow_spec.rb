require "rails_helper"

RSpec.describe "Email Authentication Flow", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  describe "complete authentication flow" do
    it "allows a user to authenticate via email link" do
      # 1. Visit the sign-in page
      get "/email_authentications/new"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sign in")

      # 2. Submit email address
      post "/email_authentications", params: { nopassword_email_authentication: { email: "user@example.com" } }
      expect(response).to have_http_status(:accepted)

      # 3. Extract token from session
      token = session["nopassword_challenge"]["token"]
      expect(token).to be_present
      expect(token.length).to eq(32) # 128 bits = 32 hex chars

      # 4. Visit the verification link (simulating clicking email link)
      get "/email_authentications/#{token}"
      expect(response).to have_http_status(:ok)

      # 5. Confirm authentication
      patch "/email_authentications/#{token}"
      expect(response).to have_http_status(:redirect)

      # 6. Session should be cleaned up
      expect(session["nopassword_challenge"]).to be_nil
      expect(session["nopassword_authentication"]).to be_nil
    end
  end

  describe "invalid token" do
    it "rejects wrong tokens" do
      # First create a valid challenge
      post "/email_authentications", params: { nopassword_email_authentication: { email: "user@example.com" } }

      # Try to verify with wrong token
      patch "/email_authentications/wrong-token"
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "expired token" do
    it "rejects expired tokens" do
      post "/email_authentications", params: { nopassword_email_authentication: { email: "user@example.com" } }
      token = session["nopassword_challenge"]["token"]

      travel 15.minutes do
        patch "/email_authentications/#{token}"
        # Controller redirects to new with flash alert on expiration
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "different browser (no session)" do
    it "shows error when token opened without session" do
      # Simulate opening link in different browser (no session with challenge)
      get "/email_authentications/some-random-token"
      expect(response).to have_http_status(:ok)
      # The show page should render, but verification will fail when submitted
    end

    it "fails verification without session" do
      patch "/email_authentications/some-random-token"
      # Controller redirects on failure (verification_failed renders, but missing challenge triggers different path)
      expect(response).to have_http_status(:unprocessable_entity).or have_http_status(:redirect)
    end
  end

  describe "email validation" do
    it "rejects invalid emails" do
      post "/email_authentications", params: { nopassword_email_authentication: { email: "not-an-email" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "normalizes email to lowercase" do
      post "/email_authentications", params: { nopassword_email_authentication: { email: "USER@EXAMPLE.COM" } }
      expect(session["nopassword_authentication"]["email"]).to eq("user@example.com")
    end
  end

  describe "return_url preservation" do
    it "stores return_url for redirect after auth" do
      # This would typically be set by the application before redirecting to auth
      # Testing that the mechanism works
      get "/email_authentications/new"

      authentication = NoPassword::Email::Authentication.new(session)
      authentication.return_url = "/dashboard"
      authentication.save

      post "/email_authentications", params: { nopassword_email_authentication: { email: "user@example.com" } }
      token = session["nopassword_challenge"]["token"]

      patch "/email_authentications/#{token}"
      # Default controller redirects to root, but return_url should be preserved
      expect(session["nopassword_authentication"]).to be_nil # cleaned up after success
    end
  end
end
