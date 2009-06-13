require 'activesupport'
require 'hpricot'

module OA
	class Namespace
    def initialize(app)
      @app = app
    end

    def method_missing(method_id,*args,&block)
      @app.send(method_id,*args,&block)
    end
	end

	class AppBase
		def initialize(world)
      @world = world
    end

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

	class Parlinfo < Namespace
		attr_reader :person_doc, :person_image
		def person_doc!(name)
			@person_doc = fixture.hpricot_doc("parlinfo_#{name.underscore.gsub(/\s+/,'_')}.html")
			self
		end
		
		def person_image!(name)
			@person_image = fixture.path("parlinfo_#{name.underscore.gsub(/\s+/,'_')}.jpg")
			self
		end
	end

	require 'people_image_downloader'
	class PeopleDownloader < Namespace
		def downloader
			@people_downloader ||= ::PeopleImageDownloader.new
		end

		def extract!
			@person_image = downloader.extract_image(parlinfo.person_doc)
			self
		end

		def extracted?
			@person_image.should_not be_nil
		end
	end

	class App < AppBase
		namespace(:fixture,:Fixtures)
		namespace(:parlinfo,:Parlinfo)
		namespace(:people_downloader,:PeopleDownloader)
	end
end
