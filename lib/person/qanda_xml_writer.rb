class Person
	class QandaXmlWriter
		def initialize(conf,parser)
			@conf   = conf
			@parser = parser
		end

		def setup!
			@xml = File.open("#{@conf.members_xml_path}/links-abc-qanda.xml", 'w')
		end

		def output

			x = Builder::XmlMarkup.new(:target => @xml, :indent => 1)
			x.instruct!

			x.peopleinfo do
				@parser.parse(@conf.write_xml_representatives,@conf.write_xml_senators) do |person,link|
					x.personinfo(:id => person.id, :mp_biography_qanda => link)
				end
			end

			@xml.close
		end


	end
end
