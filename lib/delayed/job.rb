module Delayed

  class DeserializationError < StandardError
  end                                                                                                              

  class Job < ActiveRecord::Base      
    ParseObjectFromYaml = /\!ruby\/\w+\:([^\s]+)/
    
    set_table_name :delayed_jobs
  
    class Runner
      attr_accessor :logger, :jobs
      attr_accessor :runs, :success, :failure
    
      def initialize(jobs, logger = nil)
        @jobs = jobs       
        @logger = logger
        self.runs = self.success = self.failure = 0
      end
      
      def run
        
        ActiveRecord::Base.cache do 
          ActiveRecord::Base.transaction do 
            @jobs.each do |job|
              self.runs += 1
              begin
                time = Benchmark.measure do
                  job.perform              
                  ActiveRecord::Base.uncached { job.destroy }
                  self.success += 1
                end
                logger.debug "Executed job in #{time.real}"          
              rescue DeserializationError, StandardError, RuntimeError => e
                if logger
                  logger.error "Job #{job.id}: #{e.class} #{e.message}" 
                  logger.error e.backtrace.join("\n")                   
                end
                ActiveRecord::Base.uncached { job.reshedule e.message }            
                self.failure += 1
              end
            end                               
          end
        end
      
        self
      end
    end
   
    def self.enqueue(object, priority = 0)
      raise ArgumentError, 'Cannot enqueue items which do not respond to perform' unless object.respond_to?(:perform)
    
      Job.create(:handler => object, :priority => priority)    
    end
  
    def handler=(object)
      self['handler'] = object.to_yaml
    end
  
    def handler           
      @handler ||= deserialize(self['handler'])
    end
  
    def perform
      handler.perform
    end
  
    def reshedule(message)    
      self.attempts  += 1
      self.run_at     = self.class.time_now + 5.minutes
      self.last_error = message
      save!
    end
  
    def self.peek(limit = 1)
      if limit == 1
        find(:first, :order => "priority DESC, run_at ASC", :conditions => ['run_at <= ?', time_now])
      else
        find(:all, :order => "priority DESC, run_at ASC", :limit => limit, :conditions => ['run_at <= ?', time_now])
      end
    end
    
    def self.work_off(limit = 100)
      jobs  = Job.find(:all, :conditions => ['run_at <= ?', time_now], :order => "priority DESC, run_at ASC", :limit => limit)    
    
      Job::Runner.new(jobs, logger).run
    end
  
    protected  
    
    def self.time_now
      (ActiveRecord::Base.default_timezone == :utc) ? Time.now.utc : Time.now           
    end
    
    def before_save
      self.run_at ||= self.class.time_now
    end               
    
    private
    
    def deserialize(source)   
      attempt_to_load_file = true
      
      begin 
        handler = YAML.load(source) rescue nil                    
        return handler if handler.respond_to?(:perform)  
        
        if handler.nil?
          if source =~ ParseObjectFromYaml

            # Constantize the object so that ActiveSupport can attempt 
            # its auto loading magic. Will raise LoadError if not successful.
            attempt_to_load($1)

            # If successful, retry the yaml.load
            handler = YAML.load(source)
            return handler if handler.respond_to?(:perform)              
          end
        end
        
        if handler.is_a?(YAML::Object)
          
          # Constantize the object so that ActiveSupport can attempt 
          # its auto loading magic. Will raise LoadError if not successful.
          attempt_to_load(handler.class)
        
          # If successful, retry the yaml.load
          handler = YAML.load(source)
          return handler if handler.respond_to?(:perform)  
        end
                  
        raise DeserializationError, 'Job failed to load: Unknown handler. Try to manually require the appropiate file.'   
             
      rescue TypeError, LoadError, NameError => e 
        
        raise DeserializationError, "Job failed to load: #{e.message}. Try to manually require the required file."         
      end
    end         
    
    def attempt_to_load(klass)
       klass.constantize    
    end
  
  end
end