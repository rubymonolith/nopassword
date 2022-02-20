module Magiclink
  # Handle encrypting and decrypting secrets.
  class Encryptor
    KEY_LENGTH = ActiveSupport::MessageEncryptor.key_len

    def initialize(secret_key:, salt: self.class.generate_salt, key_length: KEY_LENGTH)
      raise "salt can't be nil" if salt.nil?
      raise "secret_key can't be nil" if secret_key.nil?

      # binding.pry if secret_key.nil?
      key = ActiveSupport::KeyGenerator.new(secret_key).generate_key(salt, key_length)
      @crypt = ActiveSupport::MessageEncryptor.new(key)
    end

    def encrypt_and_sign(decrypted_data, *args, **kwargs)
      @crypt.encrypt_and_sign(decrypted_data, *args, **kwargs)
    end

    def decrypt_and_verify(encrypted_data, *args, **kwargs)
      @crypt.decrypt_and_verify(encrypted_data, *args, **kwargs)
    end

    def self.generate_salt(key_length: KEY_LENGTH)
      SecureRandom.urlsafe_base64 key_length
    end
  end
end
