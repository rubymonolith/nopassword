class NoPassword::EmailAuthenticationMailer < ApplicationMailer
  def notification_email
    @email = params[:email]
    @link = params[:link]
    mail(to: @email, subject: "Verification link")
  end
end
