# Preview all emails at http://localhost:3000/rails/mailers/nopassword/email_authentication
class NoPassword::EmailAuthenticationPreview < ActionMailer::Preview
  def notification_email
    authentication = NoPassword::EmailAuthentication.new(email: "somebody@example.com")
    NoPassword::EmailAuthenticationMailer.with(authentication: authentication).notification_email
  end
end
