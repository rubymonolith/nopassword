module NoPassword
  class OAuth::GoogleAuthorizationsController < ApplicationController
    CLIENT_ID = nil
    CLIENT_SECRET = nil
    SCOPE = "openid email profile"

    AUTHORIZATION_URL = URI("https://accounts.google.com/o/oauth2/v2/auth")
    TOKEN_URL = URI("https://www.googleapis.com/oauth2/v4/token")
    USER_INFO_URL = URI("https://www.googleapis.com/oauth2/v3/userinfo")

    before_action :validate_state_token, only: :show

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
        raise "Implement authorization_failed to handle failed authorizations", NotImplementedError
      end

      def validate_state_token
        state_token = params.fetch(:state)
        unless valid_authenticity_token?(session, state_token)
          raise ActionController::InvalidAuthenticityToken, "The state=#{state_token} token is inauthentic."
        end
      end

      # Generates the OAuth authorization URL that will redirect the user to the OAuth provider.
      # A Rails `form_authenticity_token` is used as the `state` parameter to prevent CSRF. The
      # `callback_url` is where the user is sent back to after authenticating with the OAuth provider.
      def authorization_url
        AUTHORIZATION_URL.build.query(
          client_id: CLIENT_ID,
          redirect_uri: callback_url,
          response_type: "code",
          scope: SCOPE,
          state: form_authenticity_token
        )
      end

      # Requests an OAuth access token from the OAuth provider. The access token is used for subsequent
      # requests to gather information like a users name, email, address, or whatever other information
      # The OAuth provider makes available.
      def request_access_token
        HTTP.post(TOKEN_URL, form: {
          client_id: CLIENT_ID,
          client_secret: CLIENT_SECRET,
          code: params.fetch(:code),
          grant_type: "authorization_code",
          redirect_uri: callback_url
        })
      end

      def request_user_info(access_token:)
        HTTP.auth("Bearer #{access_token}").get(USER_INFO_URL)
      end

      # The URL the OAuth provider will redirect the user back to after authenticating.
      def callback_url
        url_for(action: :show, only_path: false)
      end
  end
end