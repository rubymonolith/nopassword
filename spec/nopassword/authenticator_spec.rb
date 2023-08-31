require "spec_helper"

describe NoPassword::Authenticator do
  let(:session) { { name: "Alice's Browser" } }
  let(:other_session) { { name: "Bob's Browser" } }
  let(:alice) { NoPassword::Authenticator.new(session) }
  let(:bob) { NoPassword::Authenticator.new(other_session) }
  let(:token) { alice.generate_token }

  context "#authentic_token?" do
    it "is authentic in Alice's browser" do
      expect(alice).to be_authentic_token token
    end
    it "is not authentic in Bobs's browser" do
      expect(bob).to_not be_authentic_token token
    end
  end

  context "#authentic_code?" do
    it "is authentic in Alice's browser" do
      expect(alice).to be_authentic_code alice.decrypt(token)
    end
    it "is not authentic in Bobs's browser" do
      expect(bob).to_not be_authentic_code alice.decrypt(token)
    end
  end

  describe "token generation" do
    it "generates different tokens each time" do
      expect(alice.generate_token).to_not eql alice.generate_token
    end
  end

  describe "identical codes" do
    let(:code) { "SAMECODE" }
    before do
      allow(NoPassword::Authenticator).to receive(:generate_code).and_return(code)
    end
    it "generates different tokens" do
      expect(bob.generate_token).to_not eql alice.generate_token
    end
    describe "#authentic_code?" do
      before do
        bob.generate_token
        alice.generate_token
      end
      it "is authentic in Alice's browser" do
        expect(alice).to be_authentic_code code
      end
      it "is authentic in Bobs's browser" do
        expect(bob).to be_authentic_code code
      end
    end
    describe "#authentic_token?" do
      it "is authentic in Alice's browser" do
        expect(alice).to be_authentic_token alice.generate_token
      end
      it "is authentic in Bobs's browser" do
        expect(bob).to be_authentic_token bob.generate_token
      end
    end
  end
end