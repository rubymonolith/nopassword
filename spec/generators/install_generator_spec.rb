require "rails_helper"
require "rails/generators"
require "rails/generators/test_case"
require "generators/nopassword/install/install_generator"

RSpec.describe NoPassword::InstallGenerator, type: :generator do
  include Rails::Generators::Testing::Behavior
  include Rails::Generators::Testing::Assertions
  include FileUtils

  tests NoPassword::InstallGenerator
  destination File.expand_path("../../tmp/generator_test", __dir__)

  before do
    prepare_destination
    # Create minimal Rails structure
    mkdir_p("#{destination_root}/config")
    File.write("#{destination_root}/config/routes.rb", "Rails.application.routes.draw do\nend\n")
  end

  after do
    rm_rf(destination_root)
  end

  describe "controller generation" do
    before { run_generator }

    it "creates the email authentications controller" do
      assert_file "app/controllers/email_authentications_controller.rb"
      content = File.read("#{destination_root}/app/controllers/email_authentications_controller.rb")
      expect(content).to include("class EmailAuthenticationsController < NoPassword::EmailAuthenticationsController")
      expect(content).to include("def verification_succeeded(email)")
    end
  end

  describe "view generation" do
    before { run_generator }

    it "creates the new view" do
      assert_file "app/views/email_authentications/new.html.erb"
    end

    it "creates the create view" do
      assert_file "app/views/email_authentications/create.html.erb"
    end

    it "creates the show view" do
      assert_file "app/views/email_authentications/show.html.erb"
    end

    it "creates the mailer views" do
      assert_file "app/views/email_authentication_mailer/authentication_email.html.erb"
      assert_file "app/views/email_authentication_mailer/authentication_email.text.erb"
    end
  end

  describe "route generation" do
    before { run_generator }

    it "adds the nopassword route" do
      assert_file "config/routes.rb"
      content = File.read("#{destination_root}/config/routes.rb")
      expect(content).to include("nopassword EmailAuthenticationsController")
    end
  end
end
