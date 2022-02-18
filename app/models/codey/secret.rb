class Codey::Secret < ApplicationRecord
  self.table_name = "codey_secrets"

  # Initialize new models with all the stuff needed to encrypt
  # and store the data.
  after_initialize :assign_defaults, unless: :persisted?

  validates :data_digest, presence: true
  validates :code_digest, presence: true
  before_validation :assign_digests, on: :create

  # This is used to derive the `data_digest`, which finds the secret.
  attr_accessor :salt
  validates :salt, presence: true

  # Maximum number of times that a verification can be attempted.
  DEFAULT_REMAINING_ATTEMPTS = 3

  validates :expires_at, presence: true
  validate :expiration

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
  before_validation :decrement_remaining_attempts, on: :update

  # How long can the code live until it expires a new
  # code verification must be created
  DEFAULT_TIME_TO_LIVE = 5.minutes

  attr_reader :code
  validate :code_authenticity
  # Ensure the code is a non-empty string. The nil will
  # trigger validations and blow up the downstream Encryptor.
  def code=(code)
    @code = code.to_s if code.present?
  end

  attr_accessor :data
  validates :data, presence: true
  validate :data_tampering, on: :update

  def has_expired?
    Time.current > expires_at
  end

  def has_remaining_attempts?
    remaining_attempts.positive?
  end

  def has_tampered_data?
    self.data_digest != digest_data if persisted?
  end

  def has_authentic_code?
    self.code_digest == digest_code
  end

  def self.find_by_digest(salt:, data:)
    return if salt.nil?
    return if data.nil?

    find_by(data_digest: digest_data(salt: salt, data: data)).tap do |secret|
      if secret
        secret.data = data
        secret.salt = salt
      end
    end
  end

  def self.digest_data(salt:, data:)
    return if salt.nil?
    return if data.nil?

    Digest::SHA256.hexdigest(salt + data)
  end

  def self.digest_code(data_digest:, code:)
    return if code.nil?
    return if data_digest.nil?

    Digest::SHA256.hexdigest(data_digest + code)
  end

  private
    def decrement_remaining_attempts
      decrement! :remaining_attempts
    end

    def assign_defaults
      self.salt = Codey::Encryptor.generate_salt
      self.code ||= Codey::RandomCodeGenerator.generate_numeric_code
      self.expires_at ||= DEFAULT_TIME_TO_LIVE.from_now
      self.remaining_attempts ||= DEFAULT_REMAINING_ATTEMPTS
    end

    def assign_digests
      self.data_digest = digest_data
      self.code_digest = digest_code
    end

    def digest_data
      self.class.digest_data(salt: salt, data: data)
    end

    def digest_code
      self.class.digest_code(data_digest: data_digest, code: code)
    end

    def expiration
      errors.add(:expires_at, "has been exceeded") if has_expired?
    end

    def data_tampering
      errors.add(:data, "has been tampered") if has_tampered_data?
    end

    def code_authenticity
      errors.add(:code, "is incorrect") unless has_authentic_code?
    end
end
