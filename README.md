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

### Brute force resistance

| Approach | Entropy | Requests to crack in TTL |
|----------|---------|--------------------------|
| 6-digit code | ~20 bits | ~3,300/sec (feasible) |
| NoPassword 2.x token | 128 bits | ~10^35/sec (impossible) |

The 128-bit token is computationally impossible to brute force, even without rate limiting. You'd need more requests per second than atoms in the solar system.

### Comparison to magic links

Traditional magic links (like many "passwordless" systems) put the entire secret in the email. Anyone with the link can authenticate from any browser.

NoPassword requires the link to be opened in the same browser that requested it, adding a second factor: possession of the session.

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
    NoPassword::EmailAuthenticationMailer
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
