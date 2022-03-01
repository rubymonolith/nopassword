class NoPassword::RandomCodeGenerator
  # 6 digit random code by default.
  CODE_LENGTH = 6

  # Numeric to make input a tad easier with a number pad.
  NUMERIC_CHARACTERS = [*'0'..'9']

  # Alphanumeric, which excludes lowercase because people would typo that.
  ALPHANUMERIC_CHARACTERS = [*'A'..'Z', *'0'..'9']

  def initialize(length:, characters:)
    @length = length
    @characters = characters
  end

  def generate
    # Why not `SecureRandom#rand`? I don't actually want a number; I want a code, with
    # leading zeros, that's a string. This is the easiest way to generate that and pad it.
    #
    # This really should be a public API, but alas, its not, so I have to call
    # it privately and pass it the characters I want this to generate for the code.
    SecureRandom.send :choose, @characters, @length
  end

  # Convinence methods for generating codes throughout the application.
  class << self
    def numeric
      new length: CODE_LENGTH, characters: NUMERIC_CHARACTERS
    end

    def generate_numeric_code
      numeric.generate
    end

    def alphanumeric
      new length: CODE_LENGTH, characters: ALPHANUMERIC_CHARACTERS
    end

    def generate_alphanumeric_code
      alphanumeric.generate
    end
  end
end
