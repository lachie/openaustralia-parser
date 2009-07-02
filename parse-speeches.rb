#!/usr/bin/env ruby

$:.unshift "#{File.dirname(__FILE__)}/lib"

require 'people'
require 'hansard_parser'

require 'hansard_couch_loader'
require 'hansard_xml_writer'

require 'configuration'
require 'optparse'
require 'output'
require 'progressbar'

def parse_date(text)
  today = Date.today
  
  if text == "today"
    today
  elsif text == "yesterday"
    today - 1
  elsif text == "previous-working-day"
    # For Sunday (wday 0) and Monday (wday 1) the previous working day is last Friday otherwise it's
    # just the previous day
    if today.wday == 0
      today - 2
    elsif today.wday == 1
      today - 3
    else
      today - 1
    end
  else
    Date.parse(text)
  end
end


output = Output.new(
                    :xml   => HansardXmlWriter,
                    :couch => HansardCouchLoader
                   )

# Defaults
options = {:load_database => true, :proof => false, :force => false}

OptionParser.new do |opts|
  opts.banner = <<EOF
Usage: parse-speeches.rb [options] <from-date> [<to-date>]
    formatting of date:
      year.month.day or today or yesterday
EOF
  opts.on("--no-load", "Just generate XML and don't load up database") do |l|
    options[:load_database] = l
  end
  opts.on("--proof", "Only parse dates that are at proof stage. Will redownload and populate html cache for those dates.") do |l|
    options[:proof] = l
  end
  opts.on("--force", "On loading data into database delete records that are not in the XML") do |l|
    options[:force] = l
  end
	opts.on("--xml", "Produce scraped XML") do
		output.select! :xml
	end
	opts.on("--couch", "Load speeches into CouchDB") do
		output.select! :couch
	end
end.parse!

if ARGV.size != 1 && ARGV.size != 2
  puts "Need to supply one or two dates"
  exit!
end
    
from_date = parse_date(ARGV[0])

if ARGV.size == 1
  to_date = from_date
else
  to_date = parse_date(ARGV[1])
end

unless output.selection_valid?
	puts "You need to supply at least one output option (--xml or --couch)"
	exit!
end

conf = Configuration.new

# First load people back in so that we can look up member id's
people = PeopleCSVReader.read_members
parser = HansardParser.new(people)

output.create! {|o| o.new(conf)}
output.setup!


progress = ProgressBar.new("parse-speeches", ((to_date - from_date + 1) * 2).to_i)

# Kind of helpful to start at the end date and go backwards when using the "--proof" option. So, always going to do this now.
date = to_date
while date >= from_date
  if conf.write_xml_representatives
    reps_debates = if options[:proof]
      parser.parse_date_house_debates_only_in_proof(date, House.representatives)
    else
      parser.parse_date_house_debates(date, House.representatives)
    end

		output.output(reps_debates,date,House.representatives)
  end

  progress.inc

  if conf.write_xml_senators
    senate_debates = if options[:proof]
      parser.parse_date_house_debates_only_in_proof(date, House.senate)
    else
      parser.parse_date_house_debates(date, House.senate)
    end

		output.output(senate_debates,date,House.senate)
  end

  progress.inc
  date = date - 1
end

progress.finish


# And load up the database
if options[:load_database]
	output.finalise!(:force => options[:force], :from_date => from_date, :to_date => to_date)
end
