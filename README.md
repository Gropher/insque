# Insque

Instant queue. Background processing and message driven communication tool. Faster and simplier alternative to Resque.

## Installation

Add this line to your application's Gemfile:

    gem 'insque', :git => 'https://github.com/Gropher/Insque.git'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install insque

## Usage

At first you need to generate initializer and redis config file. Pass your sender name as parameter. 
Sender name is the unique identifier of your instance of insque. You can use several instances of insque to create message driven communication system 

    $ rails g insque:initializer somesender

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

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
