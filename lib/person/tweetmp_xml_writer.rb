require 'builder'
require 'fileutils'

class Person
	class TweetmpXmlWriter

		def initialize(conf,parser)
			@conf = conf
			@parser = parser
		end
		
		def setup!
			FileUtils::mkdir_p @conf.members_xml_path
			@xml = File.open("#{@conf.members_xml_path}/twitter.xml", 'w')
		end

		def output
			x = Builder::XmlMarkup.new(:target => @xml, :indent => 1)
			x.instruct!
			x.peopleinfo do
				@parser.parse do |person,kind,link|
					case kind
					when :screen_name
						x.personinfo(:id => person.id, :mp_twitter_screen_name => link)
					when :invite
						x.personinfo(:id => person.id, :mp_twitter_invite_tweetmp => link)
					end
				end
			end

			@xml.close
		end
	end
end
