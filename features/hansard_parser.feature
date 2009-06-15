Feature: hansard parser
	As OpenAustralia
	I want to parse the Hansard of the Australian upper and lower houses
	So that I can keep Australian Government transparent

Scenario: downloading the hansard
	Given a "house of representatives" hansard dated "2009-06-04"
	Given a parlinfo page for the hansard
	And a parlinfo xml for the hansard with id "6862-2"
	When I download the hansard
	Then I should have the hansard body

Scenario: failing to download the hansard

Scenario: downloading and patching the hansard

Scenario: parsing the hansard
