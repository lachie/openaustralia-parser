#!/usr/bin/env ruby

require File.dirname(__FILE__)+'/lib/environment'
require 'optparse'

conf = Configuration.new

puts "Reading member data..."
people = PeopleCSVReader.read_members

output = Output.new :xml => Person::LinkXmlWriter, :couch => Person::LinkCouchLoader

OptionParser.new do |opts|
	opts.on("--couch", "Load links into couchdb") { output.select! :couch }
	opts.on("--xml"  , "Generate xmls"          ) { output.select! :xml }
end.parse!(ARGV)

unless output.selection_valid?
	puts "You need to supply at least one output option (--xml or --couch)"
	exit!
end

output.create! {|k| k.new(conf,people)}
output.setup!
output.output
output.finalise!

