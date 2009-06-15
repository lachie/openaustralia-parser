Given /^a "([^\"]*)" hansard dated "([^\"]*)"$/ do |house, date|
	@app.hansard.make!(house,date)
end

Given /^a parlinfo page for the hansard$/ do
	@app.parlinfo.prepare_hansard_page!
end

Given /^a parlinfo xml for the hansard with id "([^\"]*)"$/ do |id|
	@app.parlinfo.prepare_hansard_xml!(id)
end

Given /^an xml patch for the hansard$/ do
	@app.hansard.xml_patch!
end

When /^I download the hansard$/ do
	@app.hansard_parser.make!([]).download_and_patch!
end

When /^I download and patch the hansard$/ do
	@app.hansard_parser.make!([]).download_and_patch!
end

Then /^I should have the hansard body$/ do
	@app.hansard_parser.body?
end

Then /^it should be patched with "([^\"]*)" at line "([^\"]*)"$/ do |text, line|
	@app.hansard_parser.patched?(text,line.to_i)
end
