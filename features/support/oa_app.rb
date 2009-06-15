require 'activesupport'
require 'hpricot'
require 'fake_web'
require 'ostruct'

module OA
	class Namespace
    def initialize(app)
      @app = app
			before!
    end

		def before!; end


		def self.build(ivar,&block)
			define_method("make",&block)

			define_method("make!") do |*args|
				instance_variable_set("@#{ivar}", make(*args))
				self
			end

			define_method('made') do
				instance_variable_get("@#{ivar}") || raise("Please create the #{ivar} with #make!(...) first")
			end
		end

		def make!(*args)
			@made = make(*args)
			self
		end

		def made
			@made || raise("Please create the #{self.class.to_s.underscore} with #make!(...) first")
		end
		alias :o :made

    def method_missing(method_id,*args,&block)
      @app.send(method_id,*args,&block)
    end
	end

	class AppBase
		def initialize(world)
      @world = world
			before!
    end

		def before!; end

		def self.namespace(name,klass_name)
			class_eval %{
				def #{name}
					@#{name} ||= #{klass_name}.new(self)
				end
			}
		end


    def method_missing(method_id,*args,&block)
      @world.send(method_id,*args,&block)
    end
	end




	require 'fileutils'
	class Fixtures < Namespace
		include FileUtils

		def path(name)
			File.expand_path(File.join(File.dirname(__FILE__),'..','fixtures',name))
		end

		def open(name)
			File.open(path(name))
		end

		def hpricot_doc(name)
			Hpricot(open(name))
		end

		def before!
			rm_rf tmp_path('*')
		end

		def tmp_path(name=nil)
			path = [File.dirname(__FILE__),'..','tmp']
			path << name if name
			File.expand_path(File.join(*path))
		end

		def tmp_dir(name)
			path = tmp_path(name)
			mkdir_p(path)
			path
		end

		def tmp_file(name)
			path = tmp_path(name)
			mkdir_p(File.dirname(path))
			path
		end
	end



	class FakeWeb < Namespace
		def before!
			::FakeWeb.clean_registry
			::FakeWeb.allow_net_connect = false
		end

		def prepare_for_html_get!(url,fixture_name)
			text = fixture.open(fixture_name).read
			prepare_for_string_get!(url,text)
		end

		def prepare_for_type_get!(url,fixture_name,content_type)
			text = fixture.open(fixture_name).read
			prepare_for_string_get!(url,text,content_type)
		end

		def prepare_for_file_get!(url,fixture_name)
			::FakeWeb.register_uri(:get, url, :file => fixture.path(fixture_name))
		end

		def prepare_for_string_get!(url,text,content_type='text/html')
			response = <<-EOR
HTTP/1.1 200 OK
Content-Type: #{content_type}
Content-Length: #{text.size}

#{text}
			EOR
			::FakeWeb.register_uri(:get, url, :response => response)
		end
	end


	class Parlinfo < Namespace
		attr_reader :person_doc, :person_image
		def person_doc!(name)
			@person_doc = fixture.hpricot_doc("parlinfo_#{name.underscore.gsub(/\s+/,'_')}.html")
			self
		end

		def page_content(body)
			%{<div id="content">\n#{body}\n</div>}
		end

		def prepare_not_found_page_for!(name)
			web.prepare_for_string_get!(person_url(name), page_content("No results found"))
		end

		def prepare_stub_page_for!(name)
			web.prepare_for_string_get!(person_url(name), page_content("Hooray #{name}"))
		end


		# hansard
		def prepare_hansard_page!
			web.prepare_for_html_get!(hansard_search_url, hansard_fixture('html'))
		end

		def prepare_hansard_xml!(id)
			web.prepare_for_type_get!(hansard_xml_url(id), hansard_fixture('xml'), 'text/xml')
		end

		def parlinfo_url
			"http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p"
		end
		def person_url(name)
			"#{parlinfo_url};query=Dataset:allmps%20" + name.gsub(' ', '%20')
		end

		def person_image_url(name)
			name = name.underscore.gsub(/\s+/,'_')
			"http://parlinfo.aph.gov.au/parlInfo/download/handbook/allmps/0J4/upload_ref_binary/#{name}.jpg"
		end

		def hansard_letter
			house.is_reps?(hansard.o.house) ? "r" : "s"
		end

		def hansard_search_url
			"#{parlinfo_url};query=Id:chamber/hansard#{hansard_letter}/#{hansard.o.date}/0000"
		end

		def hansard_xml_url(id)
			"http://parlinfo.aph.gov.au:80/parlInfo/download/chamber/hansard#{hansard_letter}/#{hansard.o.date}/toc_unixml/#{id}.xml"
		end

		def hansard_fixture(ext)
			base_name = "hansard_#{hansard.o.house}_#{hansard.o.date.underscore}"
			"#{base_name}.#{ext}"
		end
		

		def person_html_file(name)
			"parlinfo_#{name.underscore.gsub(/\s+/,'_')}.html"
		end

		def person_image_file(name)
			"parlinfo_#{name.underscore.gsub(/\s+/,'_')}.jpg"
		end
	end

	require 'house'
	class House < Namespace
		def interpret(house)
			if is_reps?(house)
				'reps'
			elsif house[/senate/i]
				'senate'
			else
				raise "can't interpret house '#{house}'"
			end
		end

		def make(named)
			case interpret(named)
			when 'reps'
				::House.representatives
			when 'senate'
				::House.senate
			end
		end

		def is_reps?(house)
		 !!house[/rep/i]
		end
	end

	class Hansard < Namespace
		def make(house_str,date)
			OpenStruct.new(:house => house.interpret(house_str), :date => date)
		end
	end

	require 'hansard_parser'
	class HansardParser < Namespace
		def make(people)
			::HansardParser.new(people)
		end

		def download!
			@body = o.unpatched_hansard_xml_source_data_on_date(hansard.o.date, house.make(hansard.o.house))
			self
		end

		def body?
			@body.should_not be_blank
		end
	end

	require 'person'
	class Person < Namespace
		def make(name)
			person_params = case name
											when "Bob Loblaw"
												{
													:count => 1,
													:name => Name.new(:first => 'Bob', :middle => 'Francis', :last => 'Loblaw'),
													:alternate_names => [Name.new(:first => 'Robert', :middle => 'Francis', :last => 'Loblaw')]
												}
											when "John Armitage"
												{
													:count => 2,
													:name => Name.new(:first => 'John', :middle => 'Lindsay', :last => 'Armitage')
												}
											else
												raise "Person fixture not found for #{name}"
											end
			::Person.new(person_params)
		end

		def make!(name)
			@person = make(name)
			self
		end

		def person
			@person || raise( "Please populate the person first with #make!(name)")
		end
	end

	require 'people'
	class People < Namespace
		# build a people out of person fixtures
		def make!(*names)
			names = names.flatten
			@people = ::People.new

			names.each do |name|
				@people << person.make!(name).person
			end

			self
		end

		def people
			@people || raise("Please populate people first with #make!(name_list)")
		end
	end

	require 'people_image_downloader'
	class PeopleDownloader < Namespace
		def downloader
			@people_downloader ||= ::PeopleImageDownloader.new
		end

		def download_people!(people)
			downloader.download(people, fixture.tmp_dir("small"), fixture.tmp_dir("big"))

			self
		end

		def download!
			download.download_page(page, person, fixture.tmp_dir("small"), fixture.tmp_dir("big"))
		end

		def iterate_bio_pages_of!(people)
			@pages = []
			downloader.each_person_bio_page(people) {|page| @pages << page}
			self
		end

		def iterated_pages?(names)
			names.each_with_index do |name,index|
				@pages[index].parser.to_s.should include(name)
			end
		end

		def page_count?(count)
			@pages.should have(count).items
		end


		def person_bio!(name)
			web.prepare_for_html_get!(parlinfo.person_url(name), parlinfo.person_html_file(name) )
			@person_bio = downloader.biography_page_for_person_with_name(name)
			raise "person bio not found for '#{name}'" unless @person_bio
			self
		end

		def person_bio
			raise "please populate the person_bio with #person_bio! first" if @person_bio.blank?
			@person_bio
		end


		def person_image!(name)
			web.prepare_for_file_get!(parlinfo.person_image_url(name), parlinfo.person_image_file(name))
			self
		end

		def extract_image!
			@person_image = downloader.extract_image(person_bio)
			self
		end

		def extract_name!
			@person_name = downloader.extract_name(person_bio)
			self
		end

		def extract_birthday!
			@person_birthday = downloader.extract_birthday(person_bio)
			self
		end

		def extracted_image?
			@person_image.should_not be_nil
		end

		def extracted_name?(name)
			@person_name.full_name.should == name
		end

		def extracted_birthday?(birthday)
			@person_birthday.to_s(:db).should == birthday
		end

		def images_for_people?(size,people)
			people.each do |person|
				image_for_person?(size,person)
			end
		end

		def image_for_person?(size,person)
			file = fixture.tmp_file("#{size}/#{person.id_count}.jpg")
		end
		
	end

	class App < AppBase
		def before!
			MechanizeProxyCache.perform_caching = false
		end

		namespace(:fixture,:Fixtures)
		namespace(:web,:FakeWeb)
		namespace(:parlinfo,:Parlinfo)
		namespace(:people_downloader,:PeopleDownloader)
		namespace(:person,:Person)
		namespace(:people,:People)
		namespace(:house,:House)
		namespace(:hansard,:Hansard)
		namespace(:hansard_parser,:HansardParser)
	end
end
