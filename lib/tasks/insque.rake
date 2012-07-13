namespace :insque do
  desc 'Starts insque listener'
  task :listener => :environment do
    trap('TERM') { exit 0 }
    trap('HUP') { exit 0 }
    Insque.listen
  end

  desc 'Starts insque janitor'
  task :janitor => :environment do
    trap('TERM') { exit 0 }
    trap('HUP') { exit 0 }
    Insque.janitor
  end
end
