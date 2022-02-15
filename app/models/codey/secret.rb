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
  validate :expiration

  # 6 digit random code by default
  RANDOM_CODE_LENGTH = 6

  # Numeric to make input a tad easier with the number pad.
  RANDOM_CODE_CHARACTERS = [*'0'..'9']
  # This is what it would look like for alphanumeric, sans lowercase.
  # RANDOM_CODE_CHARACTERS = [*'A'..'Z', *'0'..'9']

  # Initialize new models with all the stuff needed to encrypt
  # and store the data.
  after_initialize :assign_defaults, unless: :persisted?

  before_validation :encrypt_data

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

  def has_exceeded_verification_attempts?
    not remaining_attempts.positive?
  end

  private
    def encryptor
      Codey::Encryptor.new(secret_key: code, salt: salt)
    end

    def assign_defaults
      self.salt = Codey::Encryptor.generate_salt
      self.code ||= self.class.generate_random_code
      self.expires_at ||= TIME_TO_LIVE.from_now
      self.remaining_attempts ||= MAXIMUM_VERIFICATION_ATTEMPTS
    end

    def decrypt_and_verify
      return nil if encrypted_data.nil?
      return nil if salt.nil?
      return nil if code.nil?

      encryptor.decrypt_and_verify encrypted_data
    end

    def encrypt_data
      self.encrypted_data = encrypt_and_sign
    end

    def encrypt_and_sign
      encryptor.encrypt_and_sign data
    end

    def expiration
      errors.add(:expires_at, "has been exceeded") if has_expired?
    end

    # Generates a random numeric code for use by Codey.
    def self.generate_random_code(characters: RANDOM_CODE_CHARACTERS, length: RANDOM_CODE_LENGTH)
      # Why not `SecureRandom#rand`? I don't actually want a number; I want a code, with
      # leading zeros. This is the easiest way to generate that and pad it.
      #
      # This really should be a public API, but alas, its not, so I have to call
      # it privately and pass it the characters I want this to generate for the code.
      SecureRandom.send :choose, characters, length
    end
end
