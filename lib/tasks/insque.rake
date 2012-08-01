namespace :insque do
  desc 'Starts insque listener'
  task :listener => :environment do
    trap('QUIT') { puts "SIGTERM"; exit 0 }
    Insque.listen
  end

  desc 'Starts insque janitor'
  task :janitor => :environment do
    trap('QUIT') { puts "SIGTERM"; exit 0 }
    Insque.janitor
  end
end
