class Codey::Verification < Codey::Model
  delegate \
      :has_expired?,
      :has_remaining_attempts?,
      :has_authentic_code?,
      :expires_at,
      :remaining_attempts,
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

  def valid?(*args, **kwargs)
    secret.decrement! :remaining_attempts if persisted?
    super(*args, **kwargs)
  end

  def has_exceeded_attempts?
    not has_remaining_attempts?
  end

  def has_incorrect_code?
    not has_authentic_code?
  end

  def persisted?
    secret.present?
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
      Codey::Secret.find_by_digest(salt: salt, data: data).tap do |secret|
        secret.code = code if secret
      end
    end

    def decrement_remaining_attempts
      secret.decement! :remaining_attempts
    end
end
