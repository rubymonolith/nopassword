class Codey::EmailAuthenticationsController < ApplicationController
  before_action :assign_secret, only: %i[edit update destroy]

  def new
    @email_code = Codey::EmailAuthentication.new
  end

  def create
    @email_code = Codey::EmailAuthentication.new(email_code_params)

    if @email_code.valid?
      # Generate the secret.
      @secret = @email_code.create_secret
      # Deliver the secret via email

      # Now clear the code and decrypted data so the end-user
      # has to retreive the information via email.
      @secret.clear unless Rails.env.development?
      render :edit
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @secret.destroy!
  end

  def update
    if @secret.update secret_params
      redirect_to root_url
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def email_code_params
      params.require(:codey_email_authentication).permit(:email)
    end

    def secret_params
      params.require(:codey_secret).permit(:code, :salt)
    end

    def assign_secret
      @secret = find_secret
    end

    def find_secret
      Codey::Secret.find_by_salt! secret_params.fetch(:salt)
    end
end
