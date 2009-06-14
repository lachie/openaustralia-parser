require 'activesupport'
require 'hpricot'
require 'fake_web'

module OA
	class Namespace
    def initialize(app)
      @app = app
			before!
    end

		def before!; end

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




	class Fixtures < Namespace
		def path(name)
			File.join(File.dirname(__FILE__),'..','fixtures',name)
		end

		def open(name)
			File.open(path(name))
		end

		def hpricot_doc(name)
			Hpricot(open(name))
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

		def prepare_for_file_get!(url,fixture_name)
			::FakeWeb.register_uri(:get, url, :file => fixture.path(fixture_name))
		end

		def prepare_for_string_get!(url,text)
			response = <<-EOR
HTTP/1.1 200 OK
Content-Type: text/html
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

		def person_url(name)
			"http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Dataset:allmps%20" + name.gsub(' ', '%20')
		end

		def person_image_url(name)
			name = name.underscore.gsub(/\s+/,'_')
			"http://parlinfo.aph.gov.au/parlInfo/download/handbook/allmps/0J4/upload_ref_binary/#{name}.jpg"
		end
		

		def person_html_file(name)
			"parlinfo_#{name.underscore.gsub(/\s+/,'_')}.html"
		end

		def person_image_file(name)
			"parlinfo_#{name.underscore.gsub(/\s+/,'_')}.jpg"
		end
	end

	require 'person'
	class Person < Namespace
		def make!(name)
			person_params = case name
											when "Bob Loblaw"
												{
													:count => 1,
													:name => Name.new(:first => 'Bob', :middle => 'Francis', :last => 'Loblaw'),
													:alternate_names => [Name.new(:first => 'Robert', :middle => 'Francis', :last => 'Loblaw')]
												}
											end
			@person = ::Person.new(person_params)
			self
		end

		def person
			@person || raise( "Please populate the person first with #make(name)")
		end
	end

	require 'people_image_downloader'
	class PeopleDownloader < Namespace
		def downloader
			@people_downloader ||= ::PeopleImageDownloader.new
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
	end
end
