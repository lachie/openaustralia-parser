require File.dirname(__FILE__)+'/spec_helper'
require 'person'

describe Person do
	before do
		@person = Person.new(:count => 1,
												 :name => Name.new(:first => "Bob", :middle => "Francis", :last => 'Loblaw'),
												 :alternate_names => [
													 Name.new(:title => 'Dr', :first => "Robert", :middle => "Francis", :last => 'Loblaw')
												 ]
											)
	end

	describe "#name_variants" do
		it "returns the expected name vars" do
			@person.name_variants.should == [
				'Bob Francis Loblaw',
				'Robert Francis Loblaw',
				'Bob Loblaw',
				'Robert Loblaw'
			]
		end
	end
end
