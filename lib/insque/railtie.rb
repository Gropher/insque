require 'insque'
require 'rails'

module Insque
  class Railtie < Rails::Railtie
    rake_tasks do
      require 'tasks/insque.rake'
    end
  end
end
