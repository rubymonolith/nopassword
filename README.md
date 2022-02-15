# Codey

Codey is a toolkit that makes it easy to implement temporary, secure login codes initiated from peoples' web browsers so they can login via email, SMS, CLI, QR Codes, or any other side-channel. Codey also comes with a pre-built email login flow so you can start using it right away in your Rails application.

## Installation

Add this line to your Rails application's Gemfile by executing:

```bash
$ bundle add codey
```

Next copy over the migrations:

```bash
$ rake codey_engine:install:migrations
```

Then run the migrations:

```bash
$ rake db:migrate
```

Then add to the routes file:

```ruby
# Add to routes.rb
resource :email_authentication, to: "codey/email_authentication"
```

Finally, restart the development server and head to `http://localhost:3000/email_authentication/new`.

## Why bother?

Passwords are a huge pain. How you ask?

1. **People choose weak passwords** - Most people choose weak passwords that are easy to remember and type. In a stupid game of cat and mouse, the world has fought back with password complexity validations that drive people insane and make passwords really hard to remember.

2. **People forget passwords** - When people forget their passwords they have to go through a whole reset process that sends people some sort of code via Email, SMS, or any other side-channel. Why not just authenticate this way?

3. **Password fatigue** - People get tired of creating passwords for a website. Its a breath of fresh air when they can plugin an email address, get a code, and not have to manage yet another password.


## Security

It's paramount to understand how your authentication systems are working so you can assess whether or not the risks they present are worth it.

### How it works

1. User requests a code by entering an email address. The email address is validated based on if its well-formed or not. No other validations take place.

2. If the email address is well-formed, Rails attempts sends an email to that address with the code.

3. Rails also encrypts the email address via a `Codey::Secret`, which can only be decrypted with the code emailed to the user. Additionally, a salt is created that's stored in the users browser that is also used as the key to find the secret on the server. The combination of the code and the salt, provided by the user, is what's needed to unlock the secret.

4. The user receives the email, views the code, and either enters or copies it into the text field.
  1. If they enter the wrong code, the remaining attempts is decremented. If they exhaust all attempts, they have to request a new code and start the process over.
  2. If the user enters the correct code, the code is deemed authentic and the flow is allowed to continue. The secret that's unlocked then becomes available to the server and can be deemed as authentic, provided the developer used a proper side-channel that's reasonably secure for the risk profile.

### Features

Codey deploys the following features to mitigate brute force attacks:

#### Limit the number of times a code can be entered

Codey ships with `Codey::Secret#remaining_attempts`, which is decremented each time the user enters a code. When there's 0 remaining attempts, the secret is destroyed and the user has to request a new, uniquely generated code. By default, Codey gives end-users 3 attempts to try the code.

#### A randomly generated salt must also be provided with the code

The salt is hidden from the user by embedding it into the form payload that's posted back to the server with the code. This means an attack would have to somehow get this salt, in addition to the code, to successfully verify the secret.

The salt is not emailed or distributed to the end-user: it is kept in the browser they're using to authenticate. If an attacker intercepted the code from the side-channel, they would also need access to the salt.

#### Secret has a time-to-live

In addition to the salt and remaining attempts, a secret also has a time-to-live, which limits the amount of time a user has to guess the secret.

#### Does not store personally identifying information ("PII")

Codey makes a best effort to prevent PII from being stored on the server during the authentication & authorization process. Instead the data is persisted on the client via a `data` key, and is verified on each request to ensure the client did not tamper with the orignal PII for the final authentication request. The PII is revealed after the user successfully verifies their email address.

Code does not prevent other pieces of your infrastructure from logging PII, so you'll need to do your dilligence to ensure nothing is logged if your goal is to provide your users with strong privacy garauntees.

## Usage

### Routes

### Integration

###

## Motivations

### Why was Codey created?

The gems I evaluated all did more than I wanted them to:

1. [passwordless](https://rubygems.org/gems/passwordless) - Same idea as this gem, but it tries to do too much by including `current_user` and all of the before_action callbacks. Ultimately this gem wasn't suitable for me because I found they way its architected makes it difficult to extend or plug into existing application code.

2. [devise-passwordless](https://rubygems.org/gems/devise-passwordless) - This would be a good solution if you're already using devise, but like passwordless, I didn't want a gem that got into the business of `current_user`. Additionally, for new passwordless-only applications, it doesn't make sense to start with devise since it makes many assumptions about requiring a username and password.

Codey only worries about generating codes and creating a secure environment for end-users to validate the codes.

### Why was it not built into devise, warden, or ominauth?

I initially thought this would make for a great OmniAuth strategy, but quickly realized OmniAuth has a goal of being agnostic to rails and ships Rack middleware. I needed something more integrated into Rails controllers and views so that I could more easily extend in various projects.

Devise already has [devise-passwordless](https://rubygems.org/gems/devise-passwordless), but it tries to do too much for my purposes by managing user authorization. I needed something that stopped short of managing user authorization.

## Contributing

I'd like to build out a set of controllers, views, etc. for common use cases for codes, like SMS, QRCode, and email. If you'd like to contribute, lets talk about it at https://github.com/rocketshipio/codey/discussions/categories/ideas before you code anything and go over architectural principals, how to distribute, etc.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
