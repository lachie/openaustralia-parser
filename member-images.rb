#!/usr/bin/env ruby

require File.dirname(__FILE__)+'/lib/environment'
require 'optparse'

conf = Configuration.new
output = Output.new :couch => Person::ImageCouchLoader,
										:file => Person::ImageFileWriter

OptionParser.new do |opts|
	opts.on("--couch", "Load images into couchdb") { output.select! :couch }
	opts.on("--file" , "Download and save images") { output.select! :file  }
end.parse!(ARGV)

unless output.selection_valid?
	puts "You need to supply at least one output option (--file or --couch)"
	exit!
end

output.create! {|k| k.new(conf)}

output.with(:file) do |f|
	f.large_image_path = "#{conf.file_image_path}/mpsL"
	f.small_image_path = "#{conf.file_image_path}/mps"
end

people = PeopleCSVReader.read_members

puts "Downloading person images..."
people.download_images(output)

output.finalise!
