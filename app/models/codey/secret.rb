class Codey::Secret < ApplicationRecord
  self.table_name = "codey_secrets"

  validates :salt, presence: true
  validates :encrypted_data, presence: true

  # Maximum number of times that a verification can be attempted.
  MAXIMUM_VERIFICATION_ATTEMPTS = 3

  validates :remaining_attempts,
    presence: true,
    numericality: {
      only_integer: true,
      greater_than: 0 }

  # How long can the code live until it expires a new
  # code verification must be created
  TIME_TO_LIVE = 5.minutes

  validates :expires_at, presence: true
  validate :expires_at_exceeded

  # 6 digit random numeric code
  MAXIMUM_RANDOM_NUMBER = 999_999

  # Initialize new models with all the stuff needed to encrypt
  # and store the data.
  after_initialize :assign_defaults, unless: :persisted?

  before_validation :encrypt_sign_and_persist_data

  attr_reader :code
  def code=(code)
    @code = code.to_s if code
  end

  attr_writer :data
  def data
    @data ||= decrypt_and_verify
  end

  def has_expired?
    Time.now > expires_at
  end

  def clear
    @data = @code = nil
  end

  private
    def encryptor
      Codey::Encryptor.new(secret_key: code, salt: salt)
    end

    def decrypt_and_verify
      # If the model isn't persisted, then return a nil value.
      return nil unless persisted?

      decrement! :remaining_attempts
      encryptor.decrypt_and_verify encrypted_data
    end

    def assign_defaults
      self.salt = Codey::Encryptor.generate_salt
      self.code ||= self.class.generate_random_code
      self.expires_at ||= TIME_TO_LIVE.from_now
      self.remaining_attempts ||= MAXIMUM_VERIFICATION_ATTEMPTS
    end

    def encrypt_sign_and_persist_data
      self.encrypted_data = encrypt_and_sign
    end

    def encrypt_and_sign
      encryptor.encrypt_and_sign data
    end

    def expires_at_exceeded
      errors.add(:expires_at, "has passed") if has_expired?
    end

    # Generates a random numeric code for use by Codey.
    def self.generate_random_code
      SecureRandom.random_number MAXIMUM_RANDOM_NUMBER
    end
end
