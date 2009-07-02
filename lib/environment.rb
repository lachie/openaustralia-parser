# Set specific versions of gems that are needed here.
# This avoids spreading it out throughout the codebase


$:.unshift File.dirname(__FILE__)
require 'core_ext/string'
require 'core_ext/array'

require 'rubygems'
gem 'activesupport', ">= 2.2"
gem 'mechanize', "= 0.9.2"
gem 'htmlentities'

gem 'builder'
gem 'log4r'

gem 'mini_magick'

# test only
gem 'rspec'
gem 'rcov'
gem 'rr'


