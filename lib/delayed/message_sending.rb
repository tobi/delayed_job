module Delayed
  module MessageSending
    def send_later(method, *args)                                
      Delayed::Job.enqueue Delayed::PerformableMethod.new(self, method.to_sym, args)
    end
  end  
end