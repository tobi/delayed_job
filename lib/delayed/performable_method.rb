module Delayed
  class PerformableMethod < Struct.new(:object, :method, :args)    
    AR_STRING_FORMAT = /^AR\:([A-Z]\w+)\:(\d+)$/
    
    def initialize(object, method, args)
      raise NoMethodError, "undefined method `#{method}' for #{self.inspect}" unless object.respond_to?(method)
      
      self.object = dump(object)
      self.args   = args.map { |a| dump(a) }
      self.method = method.to_sym
    end
    
    def perform
      load(object).send(method, *args.map{|a| load(a)})
    rescue ActiveRecord::RecordNotFound
      # We cannot do anything about objects which were deleted in the meantime
      true    
    end               
    
    private

    def load(arg)
      case arg
      when AR_STRING_FORMAT then $1.constantize.find($2)
      else arg
      end
    end
      
    def dump(arg)
      case arg
      when ActiveRecord::Base then ar_to_string(arg)
      else arg
      end        
    end
        
    def ar_to_string(obj)
      "AR:#{obj.class}:#{obj.id}"
    end    
  end
end