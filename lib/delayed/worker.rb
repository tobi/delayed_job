module Delayed
  class Worker
    SLEEP = 5

    def initialize(options={})
      @quiet = options[:quiet]
      Delayed::Job.min_priority = options[:min_priority] if options.has_key?(:min_priority)
      Delayed::Job.max_priority = options[:max_priority] if options.has_key?(:max_priority)
    end                                                                          

    def start
      say "*** Starting job worker #{Delayed::Job.worker_name}"

      trap('TERM') { say 'Exiting...'; $exit = true }
      trap('INT')  { say 'Exiting...'; $exit = true }

      loop do      
        result = nil                                 

        realtime = Benchmark.realtime do  
          result = Delayed::Job.work_off      
        end                                                                          

        count = result.sum

        break if $exit

        if count.zero? 
          sleep(SLEEP)
        else
          say "#{count} jobs processed at %.4f j/s, %d failed ..." % [count / realtime, result.last]          
        end

        break if $exit
      end                                                                        
      
      def say(text)
        puts text unless @quiet
        RAILS_DEFAULT_LOGGER.info text
      end
     
    end
  end
end
