Given /^a parlinfo person page "([^\"]*)"$/ do |name|
	@app.people_downloader.person_bio!(name)
end

Given /^not-found parlinfo pages for "([^\"]*)"$/ do |name_list|
	name_list.split(/\s*,\s*/).each do |name|
		@app.parlinfo.prepare_not_found_page_for!(name)
	end
end
Given /^a not\-found parlinfo page for "([^\"]*)"$/ do |name|
	@app.parlinfo.prepare_not_found_page_for!(name)
end

Given /^a parlinfo person page for "([^\"]*)" \(stubbed\)$/ do |name|
	@app.parlinfo.prepare_stub_page_for!(name)
end



Given /^an image of "([^\"]*)"$/ do |name|
	@app.people_downloader.person_image!(name)
end

When /^I extract the image$/ do
	@app.people_downloader.extract_image!
end

When /^I extract the name$/ do
	@app.people_downloader.extract_name!
end

When /^I extract the birthday$/ do
	@app.people_downloader.extract_birthday!
end


# Then
#

Then /^the image has been extracted$/ do
	@app.people_downloader.extracted_image?
end

Then /^the extracted name is "([^\"]*)"$/ do |name|
	@app.people_downloader.extracted_name?(name)
end

Then /^the extracted birthday is "([^\"]*)"$/ do |bday|
	@app.people_downloader.extracted_birthday?(bday)
end
