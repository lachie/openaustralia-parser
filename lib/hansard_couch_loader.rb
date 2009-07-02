require 'couchrest'

class HansardCouchLoader
	def initialize(conf)
		@conf = conf
	end


	def setup!
	end

	def output(debates,date,house)
		debates.items.each do |item|
			puts item.class
		end
	end
end
