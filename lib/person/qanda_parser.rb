require 'mechanize'

class Person
	class QandaParser
		def initialize(conf,people)
			@conf = conf
			@people = people
			@agent = WWW::Mechanize.new
		end

		def parse_reps(&block)
			# First get mapping between constituency name and web page
			page = @agent.get(@conf.qanda_electorate_url)
			map = {}

			page.links[35..184].each do |link|
				map[link.text.downcase] = (page.uri + link.uri).to_s
			end
			# Hack to deal with "Flynn" constituency incorrectly spelled as "Flyn"
			map["flynn"] = "http://www.abc.net.au/tv/qanda/mp-profiles/flyn.htm"

			bad_divisions = []
			# Check that the links point to valid pages
			map.each_pair do |division, url|
				begin
					@agent.get(url)
				rescue WWW::Mechanize::ResponseCodeError
					bad_divisions << division
					puts "ERROR: Invalid url #{url} for division #{division}"
				end
			end
			# Clear out bad divisions
			bad_divisions.each { |division| map.delete(division) }

			@people.find_current_members(House.representatives).each do |member|
				short_division = member.division.downcase[0..3]
				link = map[member.division.downcase]

				yield(member.person, link)
				puts "ERROR: Couldn't lookup division #{member.division}" if link.nil?
			end
		end

		def parse_senators(&block)
			page = @agent.get(@conf.qanda_all_senators_url)
			page.links.each do |link|
				if link.uri.to_s =~ /^\/tv\/qanda\/senators\//
					# HACK to handle Unicode in Kerry O'Brien's name on Q&A site
					if link.to_s == "Kerry O\222Brien"
						name_text = "Kerry O'Brien"
					else
						name_text = link.to_s
					end

					member = @people.find_member_by_name_current_on_date(Name.title_first_last(name_text), Date.today, House.senate)
					if member.nil?
						puts "WARNING: Can't find Senator #{link}"
					else
						yield(member.person, page.uri + link.uri)
					end
				end
			end
		end

		def parse(reps,senators,&block)
			if reps
				parse_reps(&block)
			end

			if senators
				parse_senators(&block)
			end
		end

	end
end
