require "rails_helper"

RSpec.describe NoPassword::EmailAuthenticationMailer, type: :mailer do
  let(:email) { "user@example.com" }
  let(:url) { "http://example.com/email_authentication/abc123" }
  let(:mail) do
    described_class.with(email: email, url: url).authentication_email
  end

  describe "#authentication_email" do
    it "sends to the email" do
      expect(mail.to).to eq([email])
    end

    it "has a subject" do
      expect(mail.subject).to be_present
    end

    it "includes the URL in the body" do
      expect(mail.body.encoded).to include(url)
    end

    it "includes instructions about same browser" do
      expect(mail.body.encoded).to include("same browser")
    end

    it "mentions the expiration" do
      expect(mail.body.encoded).to include("10 minutes")
    end

    describe "HTML part" do
      let(:html_body) { mail.html_part.body.decoded }

      it "includes a clickable link" do
        expect(html_body).to include("<a href=\"#{url}\"")
      end
    end

    describe "text part" do
      let(:text_body) { mail.text_part.body.decoded }

      it "includes the URL" do
        expect(text_body).to include(url)
      end
    end
  end
end
