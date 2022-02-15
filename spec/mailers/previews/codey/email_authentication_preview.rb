# Preview all emails at http://localhost:3000/rails/mailers/codey/email_authentication
class Codey::EmailAuthenticationPreview < ActionMailer::Preview
  def notification_email
    authentication = Codey::EmailAuthentication.new(email: "somebody@example.com")
    Codey::EmailAuthenticationMailer.with(authentication: authentication).notification_email
  end
end
