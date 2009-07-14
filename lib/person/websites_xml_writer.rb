
class Person
	class WebsitesXmlWriter

		def initialize(conf,parser)
			@conf   = conf
			@parser = parser
		end

		def setup!
			@xml = File.open("#{@conf.members_xml_path}/websites.xml", 'w')
		end

		def output
			x = Builder::XmlMarkup.new(:target => @xml, :indent => 1)
			x.instruct!

			x.peopleinfo do
				if @conf.write_xml_representatives
					@parser.parse_representatives do |_,params|
						x.personinfo(params)
					end
				end

				if @conf.write_xml_senators
					@parser.parse_senate do |_,params|
						x.personinfo(params)
					end
				end
			end

			@xml.close
		end
	end
end
