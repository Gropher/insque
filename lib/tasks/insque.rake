namespace :insque do
  desc 'Starts insque listener and janitor'
  task :run => :environment do
    trap('TERM') { puts "SIGTERM"; exit 0 }
    threads = []
    threads << Thread.new() { Insque.listen }
    threads << Thread.new() { Insque.janitor }
    threads.each {|t| t.join }
  end

  desc 'Starts insque listener'
  task :listener => :environment do
    trap('TERM') { puts "SIGTERM"; exit 0 }
    Insque.listen
  end

  desc 'Starts insque janitor'
  task :janitor => :environment do
    trap('TERM') { puts "SIGTERM"; exit 0 }
    Insque.janitor
  end
end
