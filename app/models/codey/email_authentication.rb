require "uri"

class Codey::EmailAuthentication < Codey::Model
  attr_accessor :email
  validates :email,
    presence: true,
    format: { with: URI::MailTo::EMAIL_REGEXP }

  def create_secret
    Codey::Secret.create! data: email
  end
end
