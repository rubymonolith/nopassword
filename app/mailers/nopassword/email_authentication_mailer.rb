class NoPassword::EmailAuthenticationMailer < ApplicationMailer
  def authentication_email
    @email = params[:email]
    @url = params[:url]
    mail(
      to: @email,
      subject: default_subject
    )
  end

  private

  def default_subject
    app_name = Rails.application.class.module_parent_name rescue "the app"
    "Sign in to #{app_name}"
  end
end
