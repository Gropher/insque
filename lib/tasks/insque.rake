namespace :insque do
  desc 'Starts insque listener'
  task :listener => :environment do
    Kernel.trap('INT') {
      Kernel.exit
    }
    Insque.listen
  end

  desc 'Starts insque janitor'
  task :janitor => :environment do
    Kernel.trap('INT') {
      Kernel.exit
    }
    Insque.janitor
  end
end
