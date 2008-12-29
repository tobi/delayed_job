namespace :jobs do
  desc "Clear the delayed_job queue."
  task :clear => :merb_env do
    Delayed::Job.delete_all
  end

  desc "Start a delayed_job worker."
  task :work => :merb_env do
    Delayed::Worker.new(:min_priority => ENV['MIN_PRIORITY'], :max_priority => ENV['MAX_PRIORITY']).start
  end
end
