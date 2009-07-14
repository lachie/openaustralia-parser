class Person
	class WebsitesCouchLoader
		def initialize(conf,parser,people)
			@conf = conf
			@parser = parser
			@people = people
		end

		def setup!
		end

		def save_links(person,params)
			if p = @people[person.couch_id]
				p['links'] = links ||= {}
				links['contact'] = params[:mp_contactdetails] if params[:mp_contactdetails]
				links['homepage'] = params[:mp_website] if params[:mp_website]
			end
		end

		def output
			if @conf.write_xml_representatives
				@parser.parse_representatives {|person,params| save_links(person,params)}
			end

			if @conf.write_xml_senators
				@parser.parse_senate {|person,params| save_links(person,params)}
			end
		end
	end
end
