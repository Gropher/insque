#!/usr/bin/env rake
require "bundler/gem_tasks"

namespace :insque do
  desc 'Starts insque listener'
  task :listener => :environment do
    Rails.logger = Logger.new(File.open("#{Rails.root}/log/insque.log"))
    Insque.listen
  end

  desc 'Starts insque janitor'
  task :listener => :environment do
    Rails.logger = Logger.new(File.open("#{Rails.root}/log/insque.log"))
    Insque.janitor
  end
end
