#!/usr/bin/env ruby
#
# Simple implementation of regression tests for xml generated by parse-members.rb
# N.B. Need to pre-populate reference xml files with those that have previously been generated.
# In other words, this is only useful for checking that any refactoring has not caused a regression in behaviour.
#

$:.unshift "#{File.dirname(__FILE__)}/../lib"

require 'configuration'
require 'people'

def compare_xml(test_file, ref_file)
  system("diff #{test_file} #{ref_file}")
  if $? != 0
    #test = "regression_failed_test.xml"
    #ref = "regression_failed_ref.xml"
    #system("tidy -xml -o #{test} #{test_file}")
    #system("tidy -xml -o #{ref} #{ref_file}")
    system("opendiff #{test_file} #{ref_file}")
    puts "ERROR: #{test_file} and #{ref_file} don't match"
    exit
  end
end

conf = Configuration.new

system("mkdir -p #{conf.members_xml_path}")

puts "Reading CSV data..."
data_path = "#{File.dirname(__FILE__)}/../data"
people = People.read_members_csv("#{data_path}/people.csv", "#{data_path}/members.csv")
people.read_ministers_csv("#{data_path}/ministers.csv")
people.read_ministers_csv("#{data_path}/shadow-ministers.csv")
puts "Writing XML..."
people.write_xml("#{conf.members_xml_path}/people.xml", "#{conf.members_xml_path}/all-members.xml",
  "#{conf.members_xml_path}/peers-ucl.xml", "#{conf.members_xml_path}/ministers.xml")

ref_path = "#{File.dirname(__FILE__)}/ref"
compare_xml("#{conf.members_xml_path}/people.xml", "#{ref_path}/people.xml")
compare_xml("#{conf.members_xml_path}/all-members.xml", "#{ref_path}/all-members.xml")
compare_xml("#{conf.members_xml_path}/peers-ucl.xml", "#{ref_path}/peers-ucl.xml")
compare_xml("#{conf.members_xml_path}/ministers.xml", "#{ref_path}/ministers.xml")
