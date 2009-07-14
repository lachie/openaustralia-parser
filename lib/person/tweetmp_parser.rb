require 'json'
require 'mechanize'

class Person
	class TweetmpParser
		def initialize(conf,people)
			@conf   = conf
			@people = people

			# Not using caching proxy since we will be running this script once a day and we
			# always want to get the new data
			@agent = WWW::Mechanize.new
		end

		def parse
			JSON.parse(@agent.get("http://tweetmp.org.au/api/mps.json").body).each do |person|
				aph_id = person["GovernmentId"].upcase
				twitter = person["TwitterScreenName"]

				# Lookup the person based on their government id
				p = @people.find_person_by_aph_id(aph_id)

				# Temporary workaround until we figure out what's going on with the aph_id's that start with '00'
				if p.nil?
					p = @people.find_person_by_aph_id("00" + aph_id)
					puts "WARNING: Couldn't find person with aph id: #{aph_id}" if p.nil?
				end

				if twitter
					yield(p, :screen_name, twitter)
				else
					# Give the URL for inviting this person to Twitter using tweetmp.org.au
					yield(p, :invite, "http://tweetmp.org.au/mps/invite/#{person["Id"]}")
				end
			end
		end
	end
end
