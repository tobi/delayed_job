namespace :jobs do
  
               
  task :work => :environment do 

    puts "*** Staring job worker #{Delayed::Job.worker_name}"
    
    SLEEP = 5
     
    trap('TERM') { puts 'Exiting...'; $exit = true }
    trap('INT')  { puts 'Exiting...'; $exit = true }

    loop do      
      result = nil                                 
  
      realtime = Benchmark.realtime do  
        result = Delayed::Job.work_off      
      end                                                                          
  
      count = result.sum
    
      break if $exit
  
      if count.zero? 
        sleep(SLEEP)
        puts 'Waiting for more jobs...'
      else
        status = "#{count} jobs processed at %.4f j/s, %d failed ..." % [count / realtime, result.last]
        RAILS_DEFAULT_LOGGER.info status
        puts status
      end
    
      break if $exit
    end
  end
end