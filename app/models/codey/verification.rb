require "uri"

class Codey::Verification < Codey::Model
  attr_accessor :salt
  validates :salt, presence: true

  attr_accessor :code
  validates :code, presence: true
  validate :authentic_code

  attr_reader :data

  private
    def secret
      @secret ||= Codey::Secret.find_by_salt! salt
    end

    def authentic_code
      @data = secret.data
    rescue
      errors.add(:code, "is not authentic")
    end
end
