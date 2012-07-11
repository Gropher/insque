require 'insque'
require 'rails'

module Insque
  class Railtie < Rails::Railtie
    rake_tasks { load 'tasks/insque.rake' }
  end
end
