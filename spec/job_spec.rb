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
    Delayed::Job.create.run_at.should_not == nil
  end 

  it "should raise ArgumentError when handler doesn't respond_to :perform" do
    lambda { Delayed::Job.enqueue(Object.new) }.should raise_error(ArgumentError)
  end
      
  it "should increase count after enqueuing items" do
    Delayed::Job.enqueue SimpleJob.new      
    Delayed::Job.count.should == 1
  end
  
  it "should return nil when peeking on empty table" do      
    Delayed::Job.peek.should == nil
  end
  
  it "should return a job when peeking a table with jobs in it" do
    Delayed::Job.enqueue SimpleJob.new      
    Delayed::Job.peek.class.should == Delayed::Job
  end              

  it "should return an array of jobs when peek is called with a count larger than zero" do
    Delayed::Job.enqueue SimpleJob.new      
    Delayed::Job.peek(2).class.should == Array
  end              
  
  it "should call perform on jobs when running work_off" do        
    SimpleJob.runs.should == 0
        
    Delayed::Job.enqueue SimpleJob.new    
    Delayed::Job.work_off(1)    
    
    SimpleJob.runs.should == 1   
  end                         
  
  it "should re-schedule by about 5 minutes when it fails to execute properly" do            
    Delayed::Job.enqueue ErrorJob.new    
    runner = Delayed::Job.work_off(1)        
    runner.success.should == 0
    runner.failure.should == 1               
    
    job = Delayed::Job.find(:first)
    job.last_error.should == 'did not work'
    job.attempts.should == 1
    job.run_at.should > Time.now + 4.minutes
    job.run_at.should < Time.now + 6.minutes    
  end                    
  
  it "should raise an DeserializationError when the job class is totally unknown" do

    job = Delayed::Job.new 
    job['handler'] = "--- !ruby/object:JobThatDoesNotExist {}"

    lambda { job.perform }.should raise_error(Delayed::DeserializationError)    
  end

  it "should try to load the class when it is unknown at the time of the deserialization" do
    job = Delayed::Job.new 
    job['handler'] = "--- !ruby/object:JobThatDoesNotExist {}"

    job.should_receive(:attempt_to_load).with('JobThatDoesNotExist').and_return(true)
     
    lambda { job.perform }.should raise_error(Delayed::DeserializationError)    
  end                  
  
  it "should try include the namespace when loading unknown objects" do
    job = Delayed::Job.new 
    job['handler'] = "--- !ruby/object:Delayed::JobThatDoesNotExist {}"
    job.should_receive(:attempt_to_load).with('Delayed::JobThatDoesNotExist').and_return(true)     
    lambda { job.perform }.should raise_error(Delayed::DeserializationError)    
  end                  
  
  
  it "should also try to load structs when they are unknown (raises TypeError)" do
    job = Delayed::Job.new 
    job['handler'] = "--- !ruby/struct:JobThatDoesNotExist {}"

    job.should_receive(:attempt_to_load).with('JobThatDoesNotExist').and_return(true)
     
    lambda { job.perform }.should raise_error(Delayed::DeserializationError)    
  end          
  
  it "should try include the namespace when loading unknown structs" do
    job = Delayed::Job.new 
    job['handler'] = "--- !ruby/struct:Delayed::JobThatDoesNotExist {}"
    job.should_receive(:attempt_to_load).with('Delayed::JobThatDoesNotExist').and_return(true)     
    lambda { job.perform }.should raise_error(Delayed::DeserializationError)    
  end                  
  
end












