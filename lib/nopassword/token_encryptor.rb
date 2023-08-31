module NoPassword
  class TokenEncryptor
    KEY_LENGTH = ActiveSupport::MessageEncryptor.key_len

    def initialize(secret_key: self.class.randon, salt: self.class.random)
      raise "salt can't be nil" if salt.nil?
      raise "secret_key can't be nil" if secret_key.nil?

      key = ActiveSupport::KeyGenerator.new(secret_key).generate_key(salt, KEY_LENGTH)
      @encryptor = ActiveSupport::MessageEncryptor.new(key)
    end

    # Encrypts and then encodes token to make it URL-safe
    def encrypt(token)
      encrypted_token = @encryptor.encrypt_and_sign(token)
      url_safe_encoded_token = Base64.urlsafe_encode64(encrypted_token)
      url_safe_encoded_token
    end

    # Decodes and then decrypts token
    def decrypt(token)
      decoded_token = Base64.urlsafe_decode64(token)
      @encryptor.decrypt_and_verify(decoded_token)
    end

    def self.random(length: KEY_LENGTH)
      SecureRandom.bytes(KEY_LENGTH)
    end
  end
end
