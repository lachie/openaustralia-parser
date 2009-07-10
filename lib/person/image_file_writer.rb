require 'fileutils'

class Person
	class ImageFileWriter
		include FileUtils
		@@SMALL_THUMBNAIL_WIDTH = 44
		@@SMALL_THUMBNAIL_HEIGHT = 59

		attr_accessor :large_image_path, :small_image_path

		def initialize(conf)
			@conf = conf
		end

		def setup!
			raise "no large image path specified" unless large_image_path
			raise "no small image path specified" unless small_image_path

			mkdir_p large_image_path
			mkdir_p small_image_path
		end

		def output_image(person,image)
			# NOTE minimagick is resizing the same image in place, based on the blob... 
			# this works ok if we do large then small, but its a big caveat!
			#
			large_img = File.join(large_image_path, "#{person.id_count}.jpg")
			image.resize("%dx%d" % [@@SMALL_THUMBNAIL_WIDTH * 2, @@SMALL_THUMBNAIL_HEIGHT * 2]).write(large_img)

			small_img = File.join(small_image_path, "#{person.id_count}.jpg")
			image.resize("%dx%d" % [@@SMALL_THUMBNAIL_WIDTH    , @@SMALL_THUMBNAIL_HEIGHT]    ).write(small_img)
		end
	end
end

