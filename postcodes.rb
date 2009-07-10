#!/usr/bin/env ruby
# Load the postcode data directly into the database

require File.dirname(__FILE__)+'/lib/environment'

require 'csv'

conf = Configuration.new

def quote_string(s)
  s.gsub(/\\/, '\&\&').gsub(/'/, "''") # ' (for ruby-mode)
end

data = CSV.readlines("data/postcodes.csv")
# Remove the first two elements
data.shift
data.shift


output = Output.new :db => Constituency::DbLoader, :couch => Constituency::CouchLoader
output.select! :couch
output.create! {|k| k.new(conf)}
output.setup!
output.validate!(data)
output.output(data)
