module NoPassword
  # Implements OAuth flow as described at https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps
  class OAuth::GithubAuthorizationsController < ApplicationController
    AUTHORIZATION_URL = URI("https://github.com/login/oauth/authorize")
    TOKEN_URL = URI("https://github.com/login/oauth/access_token")
    USER_URL = URI("https://api.github.com/user")

    def self.scope = "read:user user:email"

    before_action :require_post_request, only: :create
    before_action :validate_state_token, only: :show

    include Routable

    routes.draw do
      resource :github_authorization, only: [:create, :show]
    end

    def create
      redirect_to authorization_url.to_s, allow_other_host: true
    end

    def show
      access_token = request_access_token.parse.fetch("access_token")
      user_info = request_user_info(access_token: access_token).parse

      if user_info.any?
        Rails.logger.info "Authorization #{self.class} succeeded"
        authorization_succeeded user_info
      else
        Rails.logger.info "Authorization #{self.class} failed"
        authorization_failed
      end
    end



    protected
      def authorization_succeeded(user_info)
        redirect_to root_url
      end

      def authorization_failed
        raise NotImplementedError, "Implement authorization_failed to handle failed authorizations"
      end

      def require_post_request
        return if request.post?

        raise ActionController::RoutingError, <<~ERROR.squish
          OAuth authorization MUST be initiated via POST to prevent CSRF attacks.
          GET requests bypass Rails' built-in CSRF protection and leave your users
          vulnerable. Fix your form to use method: :post immediately.
        ERROR
      end

      def validate_state_token
        state_token = params.fetch(:state)
        unless valid_authenticity_token?(session, state_token)
          raise ActionController::InvalidAuthenticityToken, "GitHub OAuth state token is invalid"
        end
      end

      # Documentation at https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps#1-request-a-users-github-identity
      def authorization_url
        AUTHORIZATION_URL.build.query(
          client_id: self.class.client_id,
          redirect_uri: callback_url,
          scope: self.class.scope,
          state: form_authenticity_token
        )
      end

      # Documentation at https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps#2-users-are-redirected-back-to-your-site-by-github
      def request_access_token
        HTTP.headers(accept: "application/json").post(TOKEN_URL, form: {
          client_id: self.class.client_id,
          client_secret: self.class.client_secret,
          code: params.fetch(:code),
          redirect_uri: callback_url
        })
      end

      # Documentation at https://docs.github.com/en/rest/users/users#get-the-authenticated-user
      def request_user_info(access_token:)
        HTTP.auth("Bearer #{access_token}").get(USER_URL)
      end

      # The URL the OAuth provider will redirect the user back to after authenticating.
      def callback_url
        url_for(action: :show, only_path: false)
      end
  end
end
