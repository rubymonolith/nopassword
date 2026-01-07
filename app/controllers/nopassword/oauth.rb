require "http"
require "uri-builder"

module NoPassword::OAuth
  extend ActiveSupport::Concern

  # Raised when a setting method may have been exposed as an action
  class SettingExposedError < NoPassword::Error
    def initialize(name)
      super("The '#{name}' setting was requested as an action. It may have been accidentally made public. Check that this endpoint isn't accessible and rotate the secret if needed.")
    end
  end

  included do
    class_attribute :_setting_names, instance_accessor: false, default: []
  end

  class_methods do
    # Defines a private instance method for OAuth configuration.
    # Override in your subclass to provide credentials.
    #
    # Example:
    #   class GoogleAuthorizationsController < NoPassword::OAuth::GoogleAuthorizationsController
    #     private
    #     def client_id = ENV["GOOGLE_CLIENT_ID"]
    #     def client_secret = ENV["GOOGLE_CLIENT_SECRET"]
    #   end
    #
    def setting(name, default: nil)
      self._setting_names = _setting_names + [name.to_s]

      define_method(name) { default }
      private name
    end

    # Exclude settings from action_methods so they can never be routed
    def action_methods
      super - _setting_names.to_set
    end
  end

  # If somehow a setting is called as an action, raise an error
  def process_action(action_name, ...)
    if self.class._setting_names.include?(action_name.to_s)
      raise SettingExposedError, action_name
    end
    super
  end
end
