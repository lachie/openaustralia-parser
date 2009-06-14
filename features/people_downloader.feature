Feature: downloading people info from http://parlinfo.aph.gov.au

	As OpenAustralia
	I want to download people info
	To keep the site interesting and personal

Background:
	Given a parlinfo person page "Bob Loblaw"

Scenario: downloading the image
	Given an image of "Bob Loblaw"
	When I extract the image
	Then the image has been extracted

Scenario: extracting the name
	When I extract the name
	Then the extracted name is "the Hon. Robert Francis Loblaw"

Scenario: extracting the birthday
	When I extract the birthday
	Then the extracted birthday is "1943-03-12"
