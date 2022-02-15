require "uri"

class Codey::EmailAuthentication < Codey::Model
  attr_accessor :email
  validates :email,
    presence: true,
    format: { with: URI::MailTo::EMAIL_REGEXP }

  def verification
    # We don't want the code in the verification, otherwise
    # the user will set it on the subsequent request, which
    # would undermine the whole thing.
    Codey::Verification.new(code: nil, salt: secret.salt) if valid?
  end

  def code
    secret.code if valid?
  end

  def destroy!
    secret.destroy!
  end

  private
    def secret
      @secret ||= create_secret
    end

    def create_secret
      Codey::Secret.create! data: email
    end
end
