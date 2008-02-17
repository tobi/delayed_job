namespace :jobs do
               
  task :work => :environment do 
    
    SLEEP = 5
     
    trap('TERM') { puts 'Exiting...'; $exit = true }
    trap('INT')  { puts 'Exiting...'; $exit = true }

    loop do
      
      count = 0

      realtime = Benchmark.realtime do 
        count = Delayed::Job.work_off
      end

      break if $exit

      if count.zero? 
        sleep(SLEEP)
      else
        RAILS_DEFAULT_LOGGER.info "#{count} jobs completed at %.2f j/s ..." % [count / realtime]
      end
      
      break if $exit 
    end
  end
end