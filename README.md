# NoPassword

[![Ruby](https://github.com/rocketshipio/nopassword/actions/workflows/ruby.yml/badge.svg)](https://github.com/rocketshipio/nopassword/actions/workflows/ruby.yml) [![Maintainability](https://api.codeclimate.com/v1/badges/1dab74df8828deddd5f3/maintainability)](https://codeclimate.com/github/rocketshipio/nopassword/maintainability)

NoPassword is a toolkit that makes it easy to implement temporary, secure login codes initiated from peoples' web browsers so they can login via email, SMS, CLI, QR Codes, or any other side-channel. NoPassword also comes with a pre-built "Login with Email" flow so you can start using it right away in your Rails application.

## Installation

Add this line to your Rails application's Gemfile by executing:

```bash
$ bundle add nopassword
```

Next copy over the migrations, controllers, and views that you'll customize later:

```bash
$ bundle exec rails generate nopassword:install
```

Then run the migrations:

```bash
$ rake db:migrate
```

Finally, restart the development server and head to `http://localhost:3000/email_authentication/new`.

## Usage

Once NoPassword is installed, it can be customized directly from the controller and views that were installed. Start by openining the `app/controllers/email_authentications_controller.rb` file and you'll see code that looks like:

```ruby
class EmailAuthenticationsController < NoPassword::EmailAuthenticationsController
    # Override with your own logic to do something with the valid data. For
    # example, you might setup the current user session here via:
    #
    # ```
    # def verification_succeeded(email)
    #   self.current_user = User.find_or_create_by! email: email
    #   redirect_to dashboard_url
    # end
    # ```
    def verification_succeeded(email)
      redirect_to root_url
    end

    # ...
end
```

You'll want to customize this for your application. For example, if you already have an application that uses a library like `devise`, you could setup a login-by-email flow like this:

```ruby
class EmailAuthenticationsController < NoPassword::EmailAuthenticationsController
    def verification_succeeded(email)
      self.current_user = User.find_or_create_by! email: email
      redirect_to root_url
    end

    # ...
end
```

## Why bother?

Passwords are a huge pain. How you ask?

1. **People choose weak passwords** - Most people choose weak passwords that are easy to remember and type. In a stupid game of cat and mouse, the world has fought back with password complexity validations that drive people insane and make passwords really hard to remember.

2. **People forget passwords** - When people forget their passwords they have to go through a whole reset process that sends people some sort of code via Email, SMS, or any other side-channel. Why not just authenticate this way?

3. **Password fatigue** - People get tired of creating passwords for a website. Its a breath of fresh air when they can plugin an email address, get a code, and not have to manage yet another password.

## Security

It's paramount to understand how your authentication systems are working so you can assess whether or not the risks they present are worth it. NoPassword is no different; it makes certain trade-offs that you need to assess for your application.

### How it works

1. User requests a code by entering an email address. The email address is validated based on if its well-formed or not. No other validations take place.

2. If the email address is well-formed, Rails generates a random 6 digit number and a salt. The 6 digit number is emailed to the end-user and the salt is persisted in the browser they're using to login to the application.

3. Rails also encrypts the email address via a `NoPassword::Secret`, The combination of the code and the salt, provided by the user, is what's needed to unlock the secret.

4. The user receives the email, views the code, and enters it into the open browser window.
  1. If they enter the wrong code, the `remaining_attempts` field is decremented. If they exhaust all attempts, they have to request a new code and start the process over.
  2. If the end-user waits until after the `expires_at` field to enter the, they have to request a new code and start the process over.
  3. If the user enters the correct code within the alloted `remaining_attempts` and `expires_at`, the `data` from the `Secret` is decrypted and made available to your application.

Worth noting; none of the steps above require a cookie to function properly.

### Features

NoPassword deploys the following features to mitigate brute force attacks:

#### Limit the number of times a code can be entered

NoPassword ships with `NoPassword::Secret#remaining_attempts`, which is decremented each time the user enters a code. When there's 0 remaining attempts, the secret is destroyed and the user has to request a new, uniquely generated code. By default, NoPassword gives end-users 3 attempts to try the code.

#### A randomly generated salt must also be provided with the code

The salt is hidden from the user by embedding it into the form payload that's posted back to the server with the code. This means an attack would have to somehow get this salt, in addition to the code, to successfully verify the secret.

The salt is not emailed or distributed to the end-user: it is kept in the browser they're using to authenticate. If an attacker intercepted the code from the side-channel, they would also need access to the salt.

#### Secrets expire

In addition to the salt and remaining attempts, a secret also has `NoPassword::Secret#expires_at`, which limits the amount of time a user has to guess the secret. By default, NoPassword gives end-users 5 minutes to enter the code.

#### Does not store personally identifying information ("PII")

NoPassword makes a best effort to prevent PII from being stored on the server during the authentication & authorization process. Instead the data is persisted on the client via a `data` key, and is verified on each request to ensure the client did not tamper with the orignal PII for the final authentication request. The PII is revealed after the user successfully verifies their email address.

NoPassword does not prevent other pieces of your infrastructure from logging PII, so you'll need to do your dilligence to ensure nothing is logged if your goal is to provide your users with strong privacy garauntees.

#### No session or cookies required

NoPassword persists its state on the client and in an encrypted format on the server; thus a session or cookie is not required for the verification process. This serves two purposes:

1. **Privacy** - The initial authorization and verification process doesn't use cookies, so in theory if you run a tight ship, you won't have to display cookie banners during the authorization and verification process.

2. **API compatibility** - The main reason NoPassword doesn't use cookies or sessions is so it can be used to authenticate via an API. This is useful for hybrid mobile app scenarios where a user may request a login code via a native UI.

## Architecture

NoPassword takes a PORO approach to its architecture, meaning you can extend its behavior via compositions and inheritence. Because of this PORO approach, most of the configuration happens on the objects themselves via inheritance instead of a configuration file. This is a similar approach to how [authologic](https://github.com/binarylogic/authlogic) implements their authentication framework for users.

Because of this modular approach, NoPassword can be used out of the box for many use cases including:

* Login via Email
* Verify emails for logged in users
* Reset passwords for logged in users

NoPassword could be extended to work for other side-channel use cases too like login via SMS, QR code, etc.

## OAuth Authorizations

NoPassword has OAuth controllers that are designed to be the smallest possible integration with providers. To use them, create a controller in your Rails project and inherit from `NoPassword::OAuth::GoogleAuthorizationsController`

```ruby
# ./app/controllers/google_authorizations_controller.rb
class GoogleAuthorizationsController < NoPassword::OAuth::GoogleAuthorizationsController
  CLIENT_ID = ENV["GOOGLE_CLIENT_ID"]
  CLIENT_SECRET = ENV["GOOGLE_CLIENT_SECRET"]
  SCOPE = "openid email profile"

  protected
    # Here's what the callback returns.
    # {"sub"=>"117509553887278399680",
    #  "name"=>"Brad Gessler",
    #  "given_name"=>"Brad",
    #  "family_name"=>"Gessler",
    #  "picture"=>"https://lh3.googleusercontent.com/a/AAcHTtcA4Mc7yx4ABlghdRp7GzkssdmccudQu6MhlItL259oTiJs=s96-c",
    #  "email"=>"brad@example.com",
    #  "email_verified"=>true,
    #  "locale"=>"en"}
    def authorization_succeeded(user_info)
      user = User.find_or_create_by(email: user_info.fetch("email"))
      user ||= user_info.fetch("name")

      self.current_user = user
      redirect_to root_url
    end

    def authorization_failed
      # Handle the error, perhaps redirect to a different login screen.
    end
end
```

Then in `routes.rb` add the following:

```ruby
# ./config/routes.rb
resource :google_authorization
```

From your application, you'll need to kick off authorization flows by firing a non-Turbo POST request to `/google_authorization`. In this example, I create a `/google_authorization/new` page that is accessible via a `GET` request. In practice you'd probably make this a partial that you'd include on a `/sign-in` page.

```erb
<!-- ./app/views/google_authorization/new.html.erb -->
<h1>Login with Google</h1>
<% form_tag action: google_authorization_path do %>
  <%= submit_tag "Login with Google" %>
<% end %>
```

Don't forget to login to the Google Developer Console at https://code.google.com/apis/console/ and get your API keys for the ENV vars above and add the `/google_authorization` URL to the domains Google is authorized to redirect back to.

## Motivations

Understanding why something was created is important to understanding it better.

### Why was NoPassword created?

The gems I evaluated all did more than I wanted them to:

1. [passwordless](https://rubygems.org/gems/passwordless) - Same idea as this gem, but it tries to do too much by including `current_user` and all of the before_action callbacks. Ultimately this gem wasn't suitable for me because I found they way its architected makes it difficult to extend or plug into existing application code.

2. [devise-passwordless](https://rubygems.org/gems/devise-passwordless) - This would be a good solution if you're already using devise, but like passwordless, I didn't want a gem that got into the business of `current_user`. Additionally, for new passwordless-only applications, it doesn't make sense to start with devise since it makes many assumptions about requiring a username and password.

NoPassword only worries about generating codes and creating a secure environment for end-users to validate the codes.

Additionally, as I was using OmniAuth in my projects to handle OAuth authorizations, I noticed it felt more difficult than it should be, so I started creating OAuth controllers to simplify the process. I've included them here in case you find them useful.

### Why was it not built on devise, warden, or ominauth?

I initially thought this would make for a great OmniAuth strategy, but quickly realized OmniAuth has a goal of being agnostic to rails and ships Rack middleware. I needed something more integrated into Rails controllers and views so that I could more easily extend in various projects.

Additionally, I found OmniAuth was more difficult to configure for OAuth in Rails than it should be. OmniAuth required a `./config/initializers/omniauth.rb` file that builds a Rack middleware. This Rack middleware then had some hard coded URLs that would be intercepted from Rails, which made it difficult to reason between controller routes and Rack middleware routes. The NoPassword::OAuth controllers solve that problem by having both configuration and logic live in a single controller file.

Devise already has [devise-passwordless](https://rubygems.org/gems/devise-passwordless), but it tries to do too much for my purposes by managing user authorization. I needed something that stopped short of managing user authorization.

## Contributing

I'd like to build out a set of controllers, views, etc. for common use cases for codes, like SMS, QRCode, and email. If you'd like to contribute, lets talk about it at https://github.com/rocketshipio/nopassword/discussions/categories/ideas before you code anything and go over architectural principals, how to distribute, etc.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
