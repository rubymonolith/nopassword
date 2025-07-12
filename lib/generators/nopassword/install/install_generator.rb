module Nopassword
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path("templates", __dir__)

    def copy_controller_file
      copy_file "controller.rb", "app/controllers/email_authentications_controller.rb"
    end

    def copy_view_files
      directory NoPassword.root.join("app/views/nopassword/email_authentication_mailer"), 'app/views/email_authentication_mailer'
      directory NoPassword.root.join("app/views/nopassword/email_authentications"), 'app/views/email_authentications'
    end

    def add_nopassword_routes
      route "resource :email_authentication"
    end

    def copy_migration_file
      rake "no_password_engine:install:migrations"
    end
  end
end
