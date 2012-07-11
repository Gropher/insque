require 'insque'
require 'rails'

module Insque
  class Railtie < Rails::Railtie
    rake_tasks do
      import 'tasks/insque'
    end
  end
end
