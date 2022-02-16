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
    Codey::Verification.new(salt: salt) if valid?
  end

  def code
    @code ||= generate_random_code if valid?
  end

  def destroy!
    secret.destroy!
  end

  protected
    def generate_random_code
      Codey::RandomCodeGenerator.generate_numeric_code
    end

  private
    def salt
      secret.salt
    end

    def secret
      @secret ||= create_secret
    end

    def create_secret
      Codey::Secret.create! data: email, code: code
    end
end
