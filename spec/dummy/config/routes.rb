Rails.application.routes.draw do
  nopassword NoPassword::EmailAuthenticationsController

  root "nopassword/email_authentications#new"
end
