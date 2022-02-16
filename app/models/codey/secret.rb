class Codey::Secret < ApplicationRecord
  self.table_name = "codey_secrets"

  validates :salt, presence: true
  validates :encrypted_data, presence: true

  # Maximum number of times that a verification can be attempted.
  DEFAULT_REMAINING_ATTEMPTS = 3

  # Don't save values that are less than zero or equal to or greater than
  # the previous attempt. This means if the client or developer wanted to,
  # they could decrement remaining attempts by more than 1 and it would save,
  # but if it drops below 0 or is more than the previous value, it will not
  # be considered valid.
  validates :remaining_attempts,
    presence: true,
    numericality: {
      only_integer: true,
      greater_than: 0 }

  # How long can the code live until it expires a new
  # code verification must be created
  DEFAULT_TIME_TO_LIVE = 5.minutes

  validates :expires_at, presence: true
  validate :expiration

  # Initialize new models with all the stuff needed to encrypt
  # and store the data.
  after_initialize :assign_defaults, unless: :persisted?

  before_validation :encrypt_data
  after_save :clear

  attr_reader :code
  # Ensure the code is a non-empty string. The nil will
  # trigger validations and blow up the downstream Encryptor.
  def code=(code)
    @code = code.to_s if code.present?
  end

  attr_writer :data
  def data
    @data ||= decrypt_data
  end

  def has_expired?
    Time.current > expires_at
  end

  def has_remaining_attempts?
    remaining_attempts.positive?
  end

  def clear
    @data = @code = nil
  end

  private
    def assign_defaults
      self.salt = Codey::Encryptor.generate_salt
      self.code ||= Codey::RandomCodeGenerator.generate_numeric_code
      self.expires_at ||= DEFAULT_TIME_TO_LIVE.from_now
      self.remaining_attempts ||= DEFAULT_REMAINING_ATTEMPTS
    end

    def encryptor
      Codey::Encryptor.new(secret_key: code, salt: salt)
    end

    def decrypt_data
      return nil if encrypted_data.nil?
      return nil if salt.nil?
      return nil if code.nil?
      return nil unless has_remaining_attempts?

      decrement! :remaining_attempts

      encryptor.decrypt_and_verify encrypted_data
    end

    def encrypt_data
      self.encrypted_data = encryptor.encrypt_and_sign data
    end

    def expiration
      errors.add(:expires_at, "has been exceeded") if has_expired?
    end
end
