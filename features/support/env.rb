$:.unshift File.dirname(__FILE__)+'/../../lib'
require 'environment'
require 'spec/expectations'

gem 'chrisk-fakeweb'

class OurWorld
	include Spec::Matchers

	def initialize
		Configuration.global_conf['web_root'] = File.dirname(__FILE__)+"/../../../"
		@app = OA::App.new(self)
	end
end

World do
	OurWorld.new
end
