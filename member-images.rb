#!/usr/bin/env ruby

require File.dirname(__FILE__)+'/lib/environment'

conf = Configuration.new
output = Output.new :couch => Person::ImageCouchLoader,
										:file => Person::ImageFileWriter

output.select! :couch

output.create! {|k| k.new(conf)}

output.with(:file) do |f|
	f.large_image_path = "#{conf.file_image_path}/mpsL"
	f.small_image_path = "#{conf.file_image_path}/mps"
end

people = PeopleCSVReader.read_members

puts "Downloading person images..."
people.download_images(output)
