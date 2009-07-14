class Person
	class QandaCouchLoader
		def initialize(conf,parser,people)
			@conf = conf
			@parser = parser
			@people = people
		end

		def setup!
		end

		def output
			@parser.parse(@conf.write_xml_representatives,@conf.write_xml_senators) do |person,link|
				if p = @people[person.couch_id]
					p['links']['qanda'] = link
				end
			end
		end
	end
end
