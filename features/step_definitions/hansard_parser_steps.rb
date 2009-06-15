Given /^a "([^\"]*)" hansard dated "([^\"]*)"$/ do |house, date|
	@app.hansard.make!(house,date)
end

Given /^a parlinfo page for the hansard$/ do
	@app.parlinfo.prepare_hansard_page!
end

Given /^a parlinfo xml for the hansard with id "([^\"]*)"$/ do |id|
	@app.parlinfo.prepare_hansard_xml!(id)
end

When /^I download the hansard$/ do
	@app.hansard_parser.make!([]).download!
end

Then /^I should have the hansard body$/ do
	@app.hansard_parser.body?
end
