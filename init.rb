require File.dirname(__FILE__) + '/lib/delayed/message_sending'
require File.dirname(__FILE__) + '/lib/delayed/performable_method'
require File.dirname(__FILE__) + '/lib/delayed/job'

Object.send(:include, Delayed::MessageSending)