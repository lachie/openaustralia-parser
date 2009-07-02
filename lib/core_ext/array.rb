class Array
	def to_key
		map {|e| e.to_key}.join('/')
	end
end
