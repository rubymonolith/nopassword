class Magiclink::Verification < Magiclink::Model
  delegate \
      :has_expired?,
      :has_exceeded_attempts?,
      :has_authentic_code?,
      :expires_at,
      :remaining_attempts,
      :decrement_remaining_attempts,
      :persisted?,
    to: :secret,
    allow_nil: true

  attr_accessor :salt
  validates :salt, presence: true

  attr_accessor :code
  validates :code, presence: true
  validate :code_expiration
  validate :code_verification_attempts
  validate :code_authenticity

  attr_accessor :data
  validates :data, presence: true

  # This fires, even if the validation fails.
  after_validation :decrement_remaining_attempts

  def has_incorrect_code?
    not has_authentic_code?
  end

  private
    def code_authenticity
      errors.add(:code, "is incorrect") if has_incorrect_code?
    end

    def code_expiration
      errors.add(:code, "has expired") if has_expired?
    end

    def code_verification_attempts
      errors.add(:code, "verification attempts have been exceeded") if has_exceeded_attempts?
    end

    def secret
      @secret ||= Magiclink::Secret.find_by_digest(salt: salt, data: data).tap do |secret|
        secret.code = code if secret
      end
    end
end
