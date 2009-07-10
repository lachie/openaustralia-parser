require 'couchrest'
require 'couchrest/mixins/extended_attachments'
require 'mime/types'
require 'base64'

class Person

	class ImageCouchLoader
		@@SMALL_THUMBNAIL_WIDTH = 44
		@@SMALL_THUMBNAIL_HEIGHT = 59

		def initialize(conf)
			@conf = conf
		end

		def setup!
			@db = CouchRest.database!(@conf.couchdb_url)
		end

		def add_attachment(person_doc,name,image)
      if @ok
        person_doc = person_doc.update('_rev' => @ok['rev'])
      end

      @ok = @db.put_attachment(person_doc, name, image.to_blob, :content_type => 'image/jpeg')
		end

		def output_image(person,image)
			puts "fetching for #{person.couch_id}"

			person_doc = @db.get(person.couch_id)

      @ok = nil

			mime_type = 'image/jpeg' #`file -b -I #{image.path}`.chomp

			puts "writing images for #{person.couch_id}..."
			add_attachment(person_doc, 'image-original', image)

			image.resize("%dx%d" % [@@SMALL_THUMBNAIL_WIDTH * 2, @@SMALL_THUMBNAIL_HEIGHT * 2])
			add_attachment(person_doc, 'image-large', image)

			image.resize("%dx%d" % [@@SMALL_THUMBNAIL_WIDTH    , @@SMALL_THUMBNAIL_HEIGHT]    )
			add_attachment(person_doc, 'image-small', image)

		rescue RestClient::RequestFailed
			puts "failed to put attachment"
			puts $!.response
      puts $!.backtrace * $/
			raise $!
		rescue RestClient::ResourceNotFound
			puts "WARNING: #{person.couch_id} not found"
		end
	end
end
