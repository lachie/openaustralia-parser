#!/usr/bin/env ruby

require File.dirname(__FILE__)+'/lib/environment'

require 'optparse'

conf = Configuration.new
output = Output.new :couch => Register::CouchLoader

output.select! :couch


parser = Register::WebParser.new(conf)

output.create! {|k| k.new(conf,parser)}
output.setup!
output.output!
