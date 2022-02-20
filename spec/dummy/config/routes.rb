Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  resource :email_authentication, controller: "magiclink/email_authentications"

  # Defines the root path route ("/")
  root "magiclink/email_authentications#new"
end
