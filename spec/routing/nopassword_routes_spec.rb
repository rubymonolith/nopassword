require "rails_helper"

RSpec.describe "nopassword routes" do
  describe "path option" do
    before do
      Rails.application.routes.draw do
        nopassword NoPassword::EmailAuthenticationsController, path: "login"
      end
    end

    after do
      Rails.application.reload_routes!
    end

    it "generates routes with custom path" do
      expect(get: "/login/new").to route_to(controller: "nopassword/email_authentications", action: "new")
      expect(post: "/login").to route_to(controller: "nopassword/email_authentications", action: "create")
      expect(get: "/login/abc123").to route_to(controller: "nopassword/email_authentications", action: "show", id: "abc123")
      expect(patch: "/login/abc123").to route_to(controller: "nopassword/email_authentications", action: "update", id: "abc123")
      expect(delete: "/login").to route_to(controller: "nopassword/email_authentications", action: "destroy")
    end
  end

  describe "default routes" do
    before do
      Rails.application.routes.draw do
        nopassword NoPassword::EmailAuthenticationsController
      end
    end

    after do
      Rails.application.reload_routes!
    end

    it "generates routes based on controller name" do
      expect(get: "/email_authentications/new").to route_to(controller: "nopassword/email_authentications", action: "new")
      expect(post: "/email_authentications").to route_to(controller: "nopassword/email_authentications", action: "create")
      expect(get: "/email_authentications/abc123").to route_to(controller: "nopassword/email_authentications", action: "show", id: "abc123")
      expect(patch: "/email_authentications/abc123").to route_to(controller: "nopassword/email_authentications", action: "update", id: "abc123")
      expect(delete: "/email_authentications").to route_to(controller: "nopassword/email_authentications", action: "destroy")
    end
  end
end
