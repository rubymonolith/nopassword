module Codey
  # Handle encrypting and decrypting secrets.
  class Encryptor
    KEY_LENGTH = ActiveSupport::MessageEncryptor.key_len

    attr_reader :salt, :key_length

    def initialize(secret_key:, salt: self.class.generate_salt)
      @key_length = KEY_LENGTH
      @salt = salt
      composite_salt = [secret_key_base, salt].join
      key   = ActiveSupport::KeyGenerator.new(secret_key).generate_key(salt, @key_length)
      @crypt = ActiveSupport::MessageEncryptor.new(key)
    end

    def encrypt_and_sign(decrypted_data, *args, **kwargs)
      @crypt.encrypt_and_sign(decrypted_data, *args, **kwargs)
    end

    def decrypt_and_verify(encrypted_data, *args, **kwargs)
      @crypt.decrypt_and_verify(encrypted_data, *args, **kwargs)
    end

    def secret_key_base
      Rails.configuration.secret_key_base
    end

    def self.generate_salt(key_length: KEY_LENGTH)
      SecureRandom.urlsafe_base64 key_length
    end
  end
end
