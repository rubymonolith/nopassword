class Magiclink::EmailAuthenticationMailer < ApplicationMailer
  def notification_email
    @authentication = params[:authentication]
    mail(to: @authentication.email, subject: "Verification code: #{@authentication.code}")
  end
end
