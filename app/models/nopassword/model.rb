class NoPassword::Model
  include ActiveModel::Model
  include ActiveModel::Validations::Callbacks
  include ActiveModel::Attributes
  extend ActiveModel::Naming
end
