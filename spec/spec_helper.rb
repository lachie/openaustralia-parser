$:.unshift "#{File.dirname(__FILE__)}/../lib"


require 'spec'

Spec::Runner.configure do |config|
  config.mock_with :rr
end
