namespace :insque do
  desc 'Starts insque listener'
  task :listener => :environment do
    Insque.listen
  end

  desc 'Starts insque janitor'
  task :janitor => :environment do
    Insque.janitor
  end
end
