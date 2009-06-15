require File.dirname(__FILE__)+'/spec_helper'

require 'configuration'

# NOTE this is not well isolated because configuration.yml is part of the distro and is a real file
# it also assumes that the parser is a submodule so that global twfy config can be read

describe Configuration do
	def fixture_path(name)
		File.join(File.dirname(__FILE__),'fixtures',name)
	end

	describe '.global_conf' do

		before do
			Configuration.local_config_path = fixture_path('configuration-local.yml')
			@orig_config = YAML.load_file(File.dirname(__FILE__)+'/../configuration.yml')
		end
		after do
			Configuration.local_config_path = nil
			Configuration.clear_global_conf!
		end


		it "reads config" do
			%w[web_root html_cache_path log_path].each do |key|
				Configuration.global_conf.should have_key(key)
			end
		end

		it "is overridden by local" do
			Configuration.global_conf['web_root'].should_not == @orig_config['web_root']
		end

		it "substitutes root" do
			Configuration.global_conf['web_root'].should == "#{Configuration.root}/../openaustralia"
		end

		it "substitutes home" do
			Configuration.global_conf['home_body'].should == "#{ENV['HOME']}/home_body"
		end

	end

	describe "#initialize" do
		before do
			Configuration.clear_global_conf!
		end

		it "inits ok when rblib/config doesn't exist" do
			Configuration.global_conf['web_root'] = '/tmp'
			lambda { Configuration.new }.should_not raise_error
		end

		it "favours configuration.yml over my society config" do
			Configuration.new.file_image_path.should == '/Library/WebServer/Documents/openaustralia/twfy/www/docs/images/'
			Configuration.global_conf['file_image_path'] = '/tmp'
			Configuration.new.file_image_path.should == '/tmp'
		end

	end

	describe '#[]' do
	end

end
