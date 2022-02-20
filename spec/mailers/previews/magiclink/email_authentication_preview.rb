# Preview all emails at http://localhost:3000/rails/mailers/magiclink/email_authentication
class Magiclink::EmailAuthenticationPreview < ActionMailer::Preview
  def notification_email
    authentication = Magiclink::EmailAuthentication.new(email: "somebody@example.com")
    Magiclink::EmailAuthenticationMailer.with(authentication: authentication).notification_email
  end
end
