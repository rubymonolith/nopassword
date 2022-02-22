class Magiclink::InstallGenerator < Rails::Generators::Base
  source_root File.expand_path("templates", __dir__)

  def copy_controller_file
    copy_file "controller.rb", "app/controllers/email_authentications_controller.rb"
  end

  def copy_view_files
    directory Magiclink.root.join("app/views/magiclink/email_authentication_mailer"), 'app/views/email_authentication_mailer'
    directory Magiclink.root.join("app/views/magiclink/email_authentications"), 'app/views/email_authentications'
  end

  def add_magiclink_routes
    route "resource :email_authentication"
  end

  def copy_migration_file
    rake "magiclink_engine:install:migrations"
  end
end
