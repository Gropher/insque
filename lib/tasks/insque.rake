namespace :insque do
  desc 'Starts insque listener'
  task :listener => :environment do
    trap('TERM') { puts "SIGTERM"; exit 0 }
    trap('HUP') { puts "SIGHUP"; exit 0 }
    trap('INT') { puts "SIGINT"; exit 0 }
    trap('QUIT') { puts "SIGQUIT"; exit 0 }
    Insque.listen
  end

  desc 'Starts insque janitor'
  task :janitor => :environment do
    trap('TERM') { puts "SIGTERM"; exit 0 }
    trap('HUP') { puts "SIGHUP"; exit 0 }
    trap('INT') { puts "SIGINT"; exit 0 }
    trap('QUIT') { puts "SIGQUIT"; exit 0 }
    Insque.janitor
  end
end
