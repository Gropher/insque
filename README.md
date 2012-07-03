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

At first you need to generate initializer and redis config file:

    $ rails g insque:initializer

To broadcast message use:

    Insque.broadcast :message_name, {:params => {:some => :params}}

To start recieving messages you need to:

1. Create handler method in Insque module:

    def somesender_message_name message
      #TODO: Handle message somehow
    end

2. Call listen method in some background process or rake task:

    Insque.listen

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
