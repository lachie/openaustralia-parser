class Output
	def initialize(outputters={})
		@output_classes = outputters
		@selections = []
	end

	def select!(kind)
		unless @output_classes.key?(kind)
			raise "unknown outputter #{kind}"
		end
		@selections << kind
	end

	def each(&block)
		@outputters.each(&block)
	end

	def create!(&block)
		@outputters = @selections.map {|key| yield @output_classes[key]}
	end

	def selection_valid?
		!@selections.empty?
	end

	def method_missing(meth_id,*args,&block)
		@outputters.each {|o| o.send(meth_id,*args,&block)}
	end
end
