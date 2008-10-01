namespace :jobs do
  desc "Clear the delayed_job queue."
  task :clear => :environment do
    Delayed::Job.delete_all
  end
  
  desc "Start a delayed_job worker."
  task :work => :environment do 
    Delayed::Worker.new.start
  end
end
