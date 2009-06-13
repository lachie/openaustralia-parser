$:.unshift File.dirname(__FILE__)+'/../../lib'
require 'environment'
require 'spec/expectations'

class OurWorld
	include Spec::Matchers

	def initialize
		Configuration.global_conf['web_root'] = File.dirname(__FILE__)+"/../../../"
	pp "config"
	pp Configuration.global_conf
		@app = OA::App.new(self)
	end
end

World do
	OurWorld.new
end
