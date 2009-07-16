#!/usr/bin/env ruby
# Load the postcode data directly into the database

require File.dirname(__FILE__)+'/lib/environment'
require 'csv'
require 'optparse'

output = Output.new :db => Constituency::DbLoader, :couch => Constituency::CouchLoader

OptionParser.new do |opts|
	opts.on("--couch", "Load postcodes into couchdb") { output.select! :couch }
	opts.on("--db"   , "Load postcodes into the db" ) { output.select! :db }
end.parse!(ARGV)

unless output.selection_valid?
	puts "You need to supply at least one output option (--db or --couch)"
	exit!
end

conf = Configuration.new

def quote_string(s)
  s.gsub(/\\/, '\&\&').gsub(/'/, "''") # ' (for ruby-mode)
end

data = CSV.readlines("data/postcodes.csv")
# Remove the first two elements
data.shift
data.shift


output.create! {|k| k.new(conf)}
output.setup!
output.validate!(data)
output.output(data)
