class NoPassword::Model
  include ActiveModel::Model
  include ActiveModel::Validations::Callbacks
  extend ActiveModel::Naming

  def initialize(*args, **kwargs)
    super(*args, **kwargs)
    assign_defaults
  end

  protected
  # Subclasses would implement default assignments in the subclass.
  def assign_defaults
  end

  # When we're dealing with t/f values, the ||= doesn't work, so we set those
  # defaults up here.
  def assign_default(attr, val)
    self.send("#{attr}=", val) if self.send(attr).nil?
  end
end
