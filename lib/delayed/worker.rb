module Delayed
  class Worker
    SLEEP = 5

    def initialize(options={})
      @quiet = options[:quiet]
    end

    def start
      puts "*** Starting job worker #{Delayed::Job.worker_name}" unless @quiet

      trap('TERM') { puts 'Exiting...' unless @quiet; $exit = true }
      trap('INT')  { puts 'Exiting...' unless @quiet; $exit = true }

      loop do      
        result = nil                                 

        realtime = Benchmark.realtime do  
          result = Delayed::Job.work_off      
        end                                                                          

        count = result.sum

        break if $exit

        if count.zero? 
          sleep(SLEEP)
          puts 'Waiting for more jobs...' unless @quiet
        else
          status = "#{count} jobs processed at %.4f j/s, %d failed ..." % [count / realtime, result.last]
          RAILS_DEFAULT_LOGGER.info status
          puts status unless @quiet
        end

        break if $exit
      end
    end
  end
end
