module NoPassword
  # Implements OAuth flow as described at https://developer.apple.com/documentation/sign_in_with_apple/request_an_authorization_to_the_sign_in_with_apple_server
  # Additional API documentation at:
  #  - https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_rest_api
  class OAuth::AppleAuthorizationsController < ApplicationController
    CLIENT_ID = ENV["APPLE_CLIENT_ID"]
    TEAM_ID = ENV["APPLE_TEAM_ID"]
    KEY_ID = ENV["APPLE_KEY_ID"]
    PRIVATE_KEY = ENV["APPLE_PRIVATE_KEY"]  # Typically, the contents of the .p8 file
    SCOPE = "name email"

    AUTHORIZATION_URL = URI("https://appleid.apple.com/auth/authorize")
    TOKEN_URL = URI("https://appleid.apple.com/auth/token")

    before_action :validate_state_token, only: :show

    def create
      redirect_to authorization_url.to_s, allow_other_host: true
    end

    def show
      id_token = request_access_token.parse.fetch("id_token")
      user_info = decode_id_token(id_token)

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

      def authorization_url
        AUTHORIZATION_URL.build.query(
          client_id: client_id,
          redirect_uri: callback_url,
          response_type: "code",
          response_mode: "form_post",
          scope: scope,
          state: form_authenticity_token
        )
      end

      def request_access_token
        client_secret = generate_client_secret
        HTTP.post(TOKEN_URL, form: {
          client_id: client_id,
          client_secret: client_secret,
          code: params.fetch(:code),
          grant_type: "authorization_code",
          redirect_uri: callback_url
        })
      end

      def client_id
        self.class::CLIENT_ID
      end

      def team_id
        self.class::TEAM_ID
      end

      def key_id
        slef.class::KEY_ID
      end

      def private_key
        ::OpenSSL::PKey::EC.new(self.class::PRIVATE_KEY)
      end

      def decode_id_token(id_token)
        # Decode the ID token here. You will need a JWT decode library.
        # The decoded token will contain the user's information.
      end

      def generate_client_secret
        payload = {
          iss: team_id,
          aud: "https://appleid.apple.com",
          sub: client_id,
          iat: Time.now.to_i,
          exp: Time.now.to_i + 60
        }
        headers = { kid: key_id }

        ::JWT.encode(payload, private_key, "ES256", headers)
      end

      def scope
        self.class::SCOPE
      end

      # The URL the OAuth provider will redirect the user back to after authenticating.
      def callback_url
        url_for(action: :show, only_path: false)
      end
  end
end
