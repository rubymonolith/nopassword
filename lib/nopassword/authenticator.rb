module NoPassword
  class Authenticator
    DIGEST_ALGORITHM = "SHA256".freeze
    KEY_LENGTH = 32
    CODE_LENGTH = 10

    def initialize(session, encryptor: self.class.encryptor)
      @session = session
      @encryptor = encryptor
    end

    def generate_token
      code = self.class.generate_code
      @session[:token_digest] = digest(code)
      @encryptor.encrypt code
    end

    def authentic_code?(code)
      @session[:token_digest] == digest(code)
    end

    def authentic_token?(token)
      authentic_code? decrypt(token)
    end

    def decrypt(encrypted_token)
      @encryptor.decrypt(encrypted_token)
    end

    def delete
      @session.delete :key
      @session.delete :token_digest
      nil
    end

    def self.encryptor
      @encrypter ||= if defined? Rails
        TokenEncryptor.new(secret_key: Rails.application.credentials.secret_key_base)
      else
        TokenEncryptor.new
      end
    end

    private
      def key
        @session[:key] ||= random_token
      end

      def digest(data)
        OpenSSL::HMAC.hexdigest(DIGEST_ALGORITHM, key, data)
      end

      def random_token
        SecureRandom.hex(KEY_LENGTH)
      end

      def self.generate_code
        Anybase::Base62.random(CODE_LENGTH)
      end
  end
end