# Insque

Instant queue. Background processing and message driven communication tool. Faster and simplier alternative to Resque.

## Installation

Add this line to your application's Gemfile:

    gem 'insque'

And then execute:

    $ bundle

Or install it manually:

    $ gem install insque

## Usage

At first you need to generate initializer and redis config file. Pass your sender name as parameter. 
Sender name is the unique identifier of your instance of insque. You can use several instances of insque to create message driven communication system. 

    $ rails g insque:initializer somesender

### Sending

To broadcast message use:
```ruby
Insque.broadcast :message_name, {:params => {:some => :params}}
```
There is an easy way to use insque as background jobs processing. You can use `send_later` method to call any method of your rails models in background
. You still need listener running to make this work.
```ruby
@model = MyModel.first
@model.send_later :mymethod, 'some', 'params'
```

### Recieving

To start recieving messages you need to:

1. Create handler method in Insque module. First part of handler name is the name of the message sender.
```ruby
def somesender_message_name message
  #TODO: Handle message somehow
end
```

2. Call `listen` method in some background process or rake task:
```ruby
Insque.listen
```

   or just run `bundle exec rake insque:listener` from your console.

3. Call `janitor` method in some background process or rake task. Janitor will reissue failed messages or report error if message fails again. Janitor treats message as failed if it was not processed for an hour after broadcast or reissue.
```ruby
Insque.janitor
```

   or just run `bundle exec rake insque:janitor` from your console.

### Daemonizing

If you want to run insque listener as a daemon consider using [foreman](https://github.com/ddollar/foreman) for this. 

If you deploy with capistrano you may want to try a version of foreman with build in capistrano support.

Add foreman to your `Gemfile`:

    gem 'foreman' # OR
    gem 'foreman-capistrano'

Install it:

    $ bundle install  

Create `Procfile`:

    listener: bundle exec rake insque:listener
    janitor: bundle exec rake insque:janitor

Run foreman from your console:
    
    $ bundle exec foreman start

For production use modify your capistrano deploy script somewhat like this:
    
    set :default_environment, {'PATH' => "/sbin:$PATH"}  # Optional. Useful if you get errors because start or restart command not found
    set :foreman_concurrency, "\"listener=2,janitor=1\"" # How many processes of each type do you want
    require 'foreman/capistrano'
    
    after "deploy", "foreman:export"  # Export Procfile as a set of upstart jobs
    after "deploy", "foreman:restart" # You will need upstart installed on your server for this to work.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
