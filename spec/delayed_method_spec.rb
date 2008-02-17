require File.dirname(__FILE__) + '/database'
                     

class SimpleJob
  cattr_accessor :runs; self.runs = 0      
  def perform; @@runs += 1; end
end

class RandomRubyObject  
  def say_hello
    'hello'
  end  
end        

class StoryReader
  
  def read(story)
    "Epilog: #{story.tell}"    
  end
  
end


describe 'random ruby objects' do
  
  before { reset_db }

  it "should respond_to :send_later method" do
                                           
    RandomRubyObject.new.respond_to?(:send_later)   
    
  end     
  
  it "should raise a ArgumentError if send_later is called but the target method doesn't exist" do
    lambda { RandomRubyObject.new.send_later(:method_that_deos_not_exist) }.should raise_error(NoMethodError)
  end
  
  it "should add a new entry to the job table when send_later is called on it" do    
    Delayed::Job.count.should == 0
    
    RandomRubyObject.new.send_later(:to_s)

    Delayed::Job.count.should == 1
  end
  
  it "should run get the original method executed when the job is performed" do
    
    RandomRubyObject.new.send_later(:say_hello)
                               
    Delayed::Job.count.should == 1        
    Delayed::Job.peek.perform.should == 'hello'
  end
  
  it "should store the object as string if its an active record" do
    
    story = Story.create :text => 'Once upon...'     
    story.send_later(:tell)                      
    
    job =  Delayed::Job.peek 
    job.handler.class.should   == Delayed::PerformableMethod
    job.handler.object.should  == 'AR:Story:1'
    job.handler.method.should  == :tell
    job.handler.args.should    == []   
    job.perform.should == 'Once upon...'
  end 
  
  it "should store arguments as string if they an active record" do
    
    story = Story.create :text => 'Once upon...'     
    
    reader = StoryReader.new 
    reader.send_later(:read, story)
    
    job =  Delayed::Job.peek 
    job.handler.class.should   == Delayed::PerformableMethod
    job.handler.method.should  == :read
    job.handler.args.should    == ['AR:Story:1']
    job.perform.should == 'Epilog: Once upon...'     
  end
  
end