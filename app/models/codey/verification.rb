class Codey::Verification < Codey::Model
  delegate \
      :has_expired?,
      :has_remaining_attempts?,
    to: :secret,
    allow_nil: true

  attr_accessor :salt
  validates :salt, presence: true

  attr_accessor :code
  validates :code, presence: true
  validate :code_authenticity
  validate :code_expiration
  validate :code_verification_attempts

  def data
    @data if valid?
  end

  private
    def code_authenticity
      return errors.add(:code, "is incorrect") if secret.nil?
      secret.code = code
      @data = secret.data
    rescue ActiveRecord::RecordNotFound, ActiveSupport::MessageEncryptor::InvalidMessage
      errors.add(:code, "is incorrect")
    end

    def code_expiration
      errors.add(:code, "has expired") if has_expired?
    end

    def code_verification_attempts
      errors.add(:code, "verification attempts have been exceeded") unless has_remaining_attempts?
    end

    def secret
      @secret ||= Codey::Secret.find_by_salt salt
    end
end
