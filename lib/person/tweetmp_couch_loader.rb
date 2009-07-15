class Person
	class TweetmpCouchLoader
		def initialize(conf,parser,people)
			@conf = conf
			@parser = parser
			@people = people
		end

		def setup!
		end

		def output
			@parser.parse do |person,kind,link|
				if p = @people[person.couch_id]
					p['links']['twitter'] = link.to_s
				end
			end
		end
	end
end
