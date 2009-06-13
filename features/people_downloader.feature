Feature: downloading people info from http://parlinfo.aph.gov.au

	As OpenAustralia
	I want to download people info
	To keep the site interesting and personal

Scenario: downloading the image
	Given a parlinfo person page "Bob Loblaw"
	And an image of "Bob Loblaw"

	When I extract the image

	Then the image has been extracted
