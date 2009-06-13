Given /^a parlinfo person page "([^\"]*)"$/ do |name|
	@app.parlinfo.person_doc!(name)
end

Given /^an image of "([^\"]*)"$/ do |name|
	@app.parlinfo.person_image!(name)
end

When /^I extract the image$/ do
	@app.people_downloader.extract!
end

Then /^the image has been extracted$/ do
	@app.people_downloader.extracted?
end

