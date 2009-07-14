#!/usr/bin/env ruby

require File.dirname(__FILE__)+'/lib/environment'

require 'optparse'

conf = Configuration.new

puts "Reading member data..."
people = PeopleCSVReader.read_members

o = Output.new :xml => Person::LinkXmlWriter, :couch => Person::LinkCouchLoader
o.select! :couch
o.create! {|k| k.new(conf,people)}
o.setup!
o.output
o.finalise!

