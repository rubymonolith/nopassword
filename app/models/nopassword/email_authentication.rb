require "uri"

class NoPassword::EmailAuthentication < NoPassword::Model
  attribute :session
  attribute :email, :string
  attribute :expires_at, :time, default: -> { 5.minutes.from_now }
  attribute :remaining_authentication_attempts, :integer, default: 3

  delegate \
      :authentic_code?,
      :authentic_token?,
      :generate_token,
    to: :authenticator

  validates :email,
    presence: true,
    format: { with: URI::MailTo::EMAIL_REGEXP }

  def destroy
    session.destroy
  end

  def email
    session[:nopassword_unauthenticated_email]
  end

  def email=(email)
    session[:nopassword_unauthenticated_email] = email
  end

  def validate_token(token)
  end

  def validate_code(code)
  end

  def has_expired?
  end

  def has_exceeded_attempts?
  end

  # def update
  #   if @verification.valid?
  #     verification_succeeded @verification.data
  #   elsif @verification.has_expired?
  #     verification_expired @verification
  #   elsif @verification.has_exceeded_attempts?
  #     verification_exceeded_attempts @verification
  #   else
  #     render :edit, status: :unprocessable_entity
  #   end
  # end

  private
    def authenticator
      validate!
      @authenticator ||= NoPassword::Authenticator.new(session)
    end
end
