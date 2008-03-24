require File.dirname(__FILE__) + '/database'

class SimpleJob
  cattr_accessor :runs; self.runs = 0      
  def perform; @@runs += 1; end
end                                     

class ErrorJob
  cattr_accessor :runs; self.runs = 0      
  def perform; raise 'did not work'; end  
end

describe Delayed::Job do
  
  before :each do 
    reset_db
  end                  

  it "should set run_at automatically" do
    Delayed::Job.create(:payload_object => ErrorJob.new ).run_at.should_not == nil
  end 

  it "should raise ArgumentError when handler doesn't respond_to :perform" do
    lambda { Delayed::Job.enqueue(Object.new) }.should raise_error(ArgumentError)
  end
      
  it "should increase count after enqueuing items" do
    Delayed::Job.enqueue SimpleJob.new      
    Delayed::Job.count.should == 1
  end
  
  it "should call perform on jobs when running work_off" do        
    SimpleJob.runs.should == 0
        
    Delayed::Job.enqueue SimpleJob.new    
    Delayed::Job.work_off
    
    SimpleJob.runs.should == 1   
  end                         
  
  it "should re-schedule by about 1 second at first and increment this more and more minutes when it fails to execute properly" do            
    Delayed::Job.enqueue ErrorJob.new    
    runner = Delayed::Job.work_off(1)        

    job = Delayed::Job.find(:first)
    job.last_error.should == 'did not work'
    job.attempts.should == 1
    job.run_at.should > Time.now  
    job.run_at.should < Time.now + 6.minutes    
  end                    
  
  it "should raise an DeserializationError when the job class is totally unknown" do

    job = Delayed::Job.new 
    job['handler'] = "--- !ruby/object:JobThatDoesNotExist {}"

    lambda { job.payload_object.perform }.should raise_error(Delayed::DeserializationError)    
  end

  it "should try to load the class when it is unknown at the time of the deserialization" do
    job = Delayed::Job.new 
    job['handler'] = "--- !ruby/object:JobThatDoesNotExist {}"

    job.should_receive(:attempt_to_load).with('JobThatDoesNotExist').and_return(true)
     
    lambda { job.payload_object.perform }.should raise_error(Delayed::DeserializationError)    
  end                  
  
  it "should try include the namespace when loading unknown objects" do
    job = Delayed::Job.new 
    job['handler'] = "--- !ruby/object:Delayed::JobThatDoesNotExist {}"
    job.should_receive(:attempt_to_load).with('Delayed::JobThatDoesNotExist').and_return(true)     
    lambda { job.payload_object.perform }.should raise_error(Delayed::DeserializationError)    
  end                  
  
  
  it "should also try to load structs when they are unknown (raises TypeError)" do
    job = Delayed::Job.new 
    job['handler'] = "--- !ruby/struct:JobThatDoesNotExist {}"

    job.should_receive(:attempt_to_load).with('JobThatDoesNotExist').and_return(true)
     
    lambda { job.payload_object.perform }.should raise_error(Delayed::DeserializationError)    
  end          
  
  it "should try include the namespace when loading unknown structs" do
    job = Delayed::Job.new 
    job['handler'] = "--- !ruby/struct:Delayed::JobThatDoesNotExist {}"
    job.should_receive(:attempt_to_load).with('Delayed::JobThatDoesNotExist').and_return(true)     
    lambda { job.payload_object.perform }.should raise_error(Delayed::DeserializationError)    
  end                  
             
  
  describe  "when two workers are running" do
    
    before :each do
      Delayed::Job.worker_name = 'worker1'
      Delayed::Job.create :payload_object => SimpleJob.new, :locked_by => 'worker1', :locked_until => Time.now + 360      
    end
    
    it "should give exclusive access only to a single worker" do                                                     
      job = Delayed::Job.find_available.first      
      lambda { job.lock_exclusively! Time.now + 20, 'worker2' }.should raise_error(Delayed::Job::LockError)      
    end                                        

    it "should be able to get exclusive access again when the worker name is the same" do      
      job = Delayed::Job.find_available.first
      job.lock_exclusively! Time.now + 20, 'worker1'      
      job.lock_exclusively! Time.now + 21, 'worker1'
      job.lock_exclusively! Time.now + 22, 'worker1'      
    end                                        
  end
  
end












