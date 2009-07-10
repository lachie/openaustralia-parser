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
      #if person_doc['_attachments'][name]

      if @ok
        person_doc = person_doc.update('_rev' => @ok['rev'])
      end

      puts 
      
      puts @db.send(:uri_for_attachment, person_doc, name)

			#person_doc.send method, :name => name, :file => File.new(image.path)
      @ok = @db.put_attachment(person_doc, name, image.to_blob, :content_type => 'image/jpeg')

      #as = person_doc['_attachments'] ||= {}
      #a  = as[name] ||= {}
      #a['content_type'] = 'image/jpeg'
      #a['data']         = Base64.encode64(image.to_blob)
		end

		def output_image(person,image)
			puts "fetching for #{person.couch_id}"

			person_doc = @db.get(person.couch_id)
			#person_doc.extend CouchRest::Mixins::ExtendedAttachments

      @ok = nil

			mime_type = 'image/jpeg' #`file -b -I #{image.path}`.chomp

			puts "writing images for #{person.couch_id}..."
			add_attachment(person_doc, 'image-original', image)

			image.resize("%dx%d" % [@@SMALL_THUMBNAIL_WIDTH * 2, @@SMALL_THUMBNAIL_HEIGHT * 2])
			add_attachment(person_doc, 'image-large', image)

			image.resize("%dx%d" % [@@SMALL_THUMBNAIL_WIDTH    , @@SMALL_THUMBNAIL_HEIGHT]    )
			add_attachment(person_doc, 'image-small', image)

			#a = person_doc["_attachments"]
			#a.keys.each do |k|
			#	a[k].delete('content-type')
			#	a[k]['content_type'] = mime_type
			#end

			#pp a

			# @db.save_doc(person_doc)
      

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
