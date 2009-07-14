
class Person
	class WebsitesParser
		def initialize(conf,people)
			@conf = conf
			@people = people
			@agent = WWW::Mechanize.new
		end


		def extract_links(name, link)
			person = @people.find_person_by_name_current_on_date(name, Date.today)
			if person
				sub_page = @agent.click(link)
				home_page_tag = sub_page.links.find{|l| l.text =~ /personal home page/i}
				
				params = {:id => person.id, :mp_contactdetails => sub_page.uri}
				params[:mp_website] = home_page_tag.uri if home_page_tag
				yield(person,params)
			else
				puts "WARNING: Could not find person with name '#{name.full_name}'"
			end
		end

		def parse_representatives(&block)
			@agent.get(@conf.alternative_current_house_members_url).links.each do |link|
				if link.to_s =~ /Member for/
					name = Name.last_title_first(link.text.split(',')[0..1].join(','))
					extract_links(name, link, &block)
				end
			end
		end

		def parse_senate(&block)
			@agent.get(@conf.alternative_current_senate_members_url).links.each do |link|
				if link.to_s =~ /Senator/
					name = Name.last_title_first(link.to_s.split('-')[0..-2].join('-'))
					extract_links(name, link, &block)
				end
			end
		end
	end
end
