# NoPassword

[![Ruby](https://github.com/rocketshipio/nopassword/actions/workflows/ruby.yml/badge.svg)](https://github.com/rocketshipio/nopassword/actions/workflows/ruby.yml) [![Maintainability](https://api.codeclimate.com/v1/badges/1dab74df8828deddd5f3/maintainability)](https://codeclimate.com/github/rocketshipio/nopassword/maintainability)

NoPassword is a toolkit that makes it easy to implement secure, passwordless authentication via email, SMS, or any other side-channel. It also includes OAuth controllers for Google and Apple sign-in.

## Installation

Add this line to your Rails application's Gemfile:

```bash
$ bundle add nopassword
```

Then install the controllers and views:

```bash
$ bundle exec rails generate nopassword:install
```

Add the route to your `config/routes.rb`:

```ruby
nopassword EmailAuthenticationsController
```

Restart the development server and head to `http://localhost:3000/email_authentication/new`.

## How It Works

NoPassword uses a session-bound token approach:

1. User enters their email in your app
2. A 128-bit random token is generated and stored in the user's session
3. A link containing the token is emailed to the user
4. User clicks the link — it only works in the same browser that requested it

### Why is this secure?

The token in the email is useless without the matching session. An attacker who intercepts the email would need BOTH:
- The link from the email
- The victim's session cookie

If they already have the session cookie, they already have access to the session anyway.

### How is this different from other magic link gems?

Most magic link gems put the entire secret in the email. Anyone with the link can authenticate from any browser.

NoPassword binds the link to the user's session — the link only works in the browser that requested it. This adds a second factor: possession of the session cookie.

### Rate limiting

NoPassword does not rate limit email sending — that's your responsibility. Use Rails' built-in rate limiting:

```ruby
class EmailAuthenticationsController < NoPassword::EmailAuthenticationsController
  rate_limit to: 5, within: 1.minute, only: :create, with: -> {
    flash[:alert] = "Too many requests. Please wait a minute."
    redirect_to url_for(action: :new)
  }
end
```

## Usage

Customize the installed controller to integrate with your user system:

```ruby
class EmailAuthenticationsController < NoPassword::EmailAuthenticationsController
  def verification_succeeded(email)
    self.current_user = User.find_or_create_by!(email: email)
    redirect_to dashboard_url
  end
end
```

### Hook Methods

Override these methods to customize behavior:

```ruby
class EmailAuthenticationsController < NoPassword::EmailAuthenticationsController
  # Called when the user successfully verifies their email
  def verification_succeeded(email)
    redirect_to root_url
  end

  # Called when the link has expired
  def verification_expired(verification)
    flash[:alert] = "Link has expired. Please try again."
    redirect_to url_for(action: :new)
  end

  # Called when the token is invalid
  def verification_failed(verification)
    flash.now[:alert] = verification.errors.full_messages.to_sentence
    render :show, status: :unprocessable_entity
  end

  # Customize how the email is sent
  def deliver_challenge(challenge)
    EmailAuthenticationMailer
      .with(email: challenge.email, url: show_url(challenge.token))
      .authentication_email
      .deliver_later
  end

  # Default URL to redirect to after authentication
  def after_authentication_url
    root_url
  end
end
```

### Handling Different Browser

When a user opens the link in a different browser (e.g., email app's webview), the verification will fail because there's no matching session. You can detect this and show a helpful message:

```ruby
class EmailAuthenticationsController < NoPassword::EmailAuthenticationsController
  def show
    if @verification.different_browser?
      # Show a page explaining they need to copy the link to their original browser
      render :different_browser
    else
      super
    end
  end
end
```

## Ejecting for Full Control

The generator gives you views you can customize. If you need full control over the controller too, include the concern directly:

```ruby
class SessionsController < ApplicationController
  include NoPassword::ControllerConcern

  def verification_succeeded(email)
    self.current_user = User.find_or_create_by!(email: email)
    redirect_to dashboard_url
  end
end
```

Then define your own routes:

```ruby
# config/routes.rb
resource :session, only: [:new, :create, :destroy] do
  get ":id", action: :show, on: :collection
  patch ":id", action: :update, on: :collection
end
```

Or skip the concern entirely and use the models directly with your own views:

```ruby
class SessionsController < ApplicationController
  def new
    @authentication = NoPassword::Email::Authentication.new(session)
  end

  def create
    @authentication = NoPassword::Email::Authentication.new(session)
    @authentication.email = params[:email]

    if @authentication.valid? && @authentication.challenge.save
      @authentication.save
      # Send your own email
      SessionMailer.with(url: verify_url(@authentication.challenge.token)).deliver_later
      redirect_to :check_email
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @authentication = NoPassword::Email::Authentication.new(session)
    @verification = @authentication.verification(token: params[:id])
  end

  def update
    @authentication = NoPassword::Email::Authentication.new(session)
    @verification = @authentication.verification(token: params[:id])

    if @verification.verify
      self.current_user = User.find_or_create_by!(email: @authentication.email)
      @authentication.delete
      redirect_to dashboard_url
    else
      render :show, status: :unprocessable_entity
    end
  end
end
```

## Architecture

NoPassword is organized into composable modules:

```
NoPassword
├── Link                          # Token challenge/verification
│   ├── Base                      # Session storage mechanics
│   ├── Challenge                 # Generates token, stores identifier, TTL
│   └── Verification              # Validates token, checks expiration
├── Session                       # Session management
│   ├── Authentication            # Stores return_url, wraps Link
│   └── Concern                   # Controller helpers
├── Email                         # Email-specific implementation
│   ├── Authentication            # Adds email validation
│   ├── Challenge                 # Aliases identifier as email
│   └── Mailer                    # ActionMailer for sending links
├── ControllerConcern             # All controller logic
├── EmailAuthenticationsController
└── OAuth
    ├── GoogleAuthorizationsController
    └── AppleAuthorizationsController
```

### Extending for SMS or other channels

The `Link` module is channel-agnostic. To add SMS support:

```ruby
class SmsAuthentication < NoPassword::Session::Authentication
  attribute :phone, :string
  validates :phone, presence: true, format: { with: /\A\+?[1-9]\d{1,14}\z/ }

  def identifier
    phone
  end
end
```

## OAuth Authorizations

NoPassword includes OAuth controllers for Google and Apple. Create a controller that inherits from the OAuth controller:

```ruby
# ./app/controllers/google_authorizations_controller.rb
class GoogleAuthorizationsController < NoPassword::OAuth::GoogleAuthorizationsController
  CLIENT_ID = ENV["GOOGLE_CLIENT_ID"]
  CLIENT_SECRET = ENV["GOOGLE_CLIENT_SECRET"]
  SCOPE = "openid email profile"

  protected

  def authorization_succeeded(sso)
    user = User.find_or_create_by(email: sso.fetch("email"))
    user.update!(name: sso.fetch("name"))

    self.current_user = user
    redirect_to root_url
  end

  def authorization_failed
    redirect_to login_path, alert: "OAuth authorization failed"
  end
end
```

Add the route:

```ruby
# ./config/routes.rb
nopassword GoogleAuthorizationsController
```

Create a sign-in button:

```erb
<%= form_tag google_authorization_path, data: { turbo: false } do %>
  <%= submit_tag "Sign in with Google" %>
<% end %>
```

## Why NoPassword?

Passwords are a pain:

1. **People choose weak passwords** - Complexity requirements make them hard to remember
2. **People forget passwords** - Password reset flows use email anyway
3. **Password fatigue** - Users appreciate not having to create yet another password

## Contributing

If you'd like to contribute, start a discussion at https://github.com/rocketshipio/nopassword/discussions/categories/ideas.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
