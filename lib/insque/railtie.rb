require 'insque'
require 'rails'

module Insque
  class Railtie < Rails::Railtie
    rake_tasks do
      require 'lib/tasks/insque.rake'
    end
  end
end
