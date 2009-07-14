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
		@outputters = []
		@outputters_by_key = {}

		@selections.each {|key| 
			@outputters << o = yield(@output_classes[key])
			@outputters_by_key[key] = o
		}
	end

	def selected?(kind)
		!! @outputters_by_key[(kind || '').to_sym]
	end

	def with(kind)
		if o = @outputters_by_key[(kind || '').to_sym]
			yield(o)
		end
	end

	def selection_valid?
		!@selections.empty?
	end

	def method_missing(meth_id,*args,&block)
		@outputters.each {|o| o.send(meth_id,*args,&block)}
	end
end
