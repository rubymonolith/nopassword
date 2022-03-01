Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  resource :email_authentication, controller: "nopassword/email_authentications"

  # Defines the root path route ("/")
  root "nopassword/email_authentications#new"
end
