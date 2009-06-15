Feature: downloading people info from http://parlinfo.aph.gov.au

	As OpenAustralia
	I want to download people info
	To keep the site up to date

Scenario: downloading the image
	Given a parlinfo person page "Bob Loblaw"
	And an image of "Bob Loblaw"
	When I extract the image
	Then the image has been extracted

Scenario: extracting the name
	Given a parlinfo person page "Bob Loblaw"
	When I extract the name
	Then the extracted name is "the Hon. Robert Francis Loblaw"

Scenario: extracting the birthday
	Given a parlinfo person page "Bob Loblaw"
	When I extract the birthday
	Then the extracted birthday is "1943-03-12"

Scenario: finding a bio page for a person
	Given a person "Bob Loblaw"
	And not-found parlinfo pages for "Bob Francis Loblaw, Robert Francis Loblaw, Bob Loblaw"
	And a parlinfo person page for "Robert Loblaw" (stubbed)
	When I search for the bio pages
	Then the page for "Robert Loblaw" was found
	And "1" page(s) were found

Scenario: downloading a list of people
	Given a list of people "Bob Loblaw"
	And not-found parlinfo pages for "Bob Francis Loblaw, Robert Francis Loblaw"
	And a parlinfo person page "Bob Loblaw"
	And an image of "Bob Loblaw"
	When I download the list of people

	Then I should see the "small" images for the list of people
	And I should see the "big" images for the list of people

@focus
Scenario: attempting to download a person not found in parlinfo
	Given a list of people "John Armitage"
	And not-found parlinfo pages for "John Lindsay Armitage, John Armitage"
	When I download the list of people
