require 'rails/generators'

class DeviseYauthTokenGenerator < Rails::Generators::Base
  argument :sender_name, :type => :string
  
  def self.source_root
    @source_root ||= File.join(File.dirname(__FILE__), 'templates')
  end

  def create_initializer
    template 'insque.rb', 'config/initializers/insque.erb'
    template 'redis.yml', 'config/redis.yml'
  end
end
