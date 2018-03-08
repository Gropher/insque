namespace :insque do
  desc 'Starts insque listener and janitor'
  task :run => :environment do
    trap('TERM') { puts "SIGTERM"; exit 0 }
    Thread.abort_on_exception=true
    threads = []
    threads << Thread.new() { Insque.listen }
    threads << Thread.new() { Insque.janitor }
    threads << Thread.new() { Insque.slow_listen }
    threads << Thread.new() { Insque.slow_janitor }
    threads.each {|t| t.join }
  end

  desc 'Starts insque listener'
  task :listener => :environment do
    trap('TERM') { puts "SIGTERM"; exit 0 }
    Thread.abort_on_exception=true
    Insque.listen
  end

  desc 'Starts insque janitor'
  task :janitor => :environment do
    trap('TERM') { puts "SIGTERM"; exit 0 }
    Thread.abort_on_exception=true
    Insque.janitor
  end
end
