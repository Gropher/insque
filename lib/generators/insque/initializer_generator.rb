module Insque
  module Generators
    class InitializerGenerator < ::Rails::Generators::Base
      argument :sender_name, :type => :string
      
      desc 'Create a sample Insque initializer and redis config file'
      
      def self.source_root
        @source_root ||= File.join(File.dirname(__FILE__), 'templates')
      end

      def create_initializer
        template 'insque.erb', 'config/initializers/insque.rb'
        template 'redis.yml', 'config/redis.yml'
      end
    end
  end
end
