class NoPassword::EmailAuthenticationsController < ApplicationController
  include NoPassword::ControllerConcern
  include NoPassword::Routable

  routes.draw do
    resource :email_authentication, only: [:new, :create, :destroy], controller: "nopassword/email_authentications" do
      get ":id", action: :show, as: :verify, on: :collection
      patch ":id", action: :update, on: :collection
    end
  end
end
