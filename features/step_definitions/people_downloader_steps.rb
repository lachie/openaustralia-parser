When /^I download "([^\"]*)"$/ do |name|
	@app.people_downloader.download
end

When /^I search for the bio pages$/ do
	@app.people_downloader.iterate_bio_pages_of!([@app.person.person])
end

When /^I download the list of people$/ do
	@app.people_downloader.download_people!(@app.people.people)
end

Then /^the page for "([^\"]*)" was found$/ do |name_list|
	names = name_list.split(/\s*,\s*/)
	@app.people_downloader.iterated_pages?(names)
end

Then /^"([^\"]*)" page\(s\) were found$/ do |count|
	@app.people_downloader.page_count?(count.to_i)
end

Then /^I should see the "([^\"]*)" images for the list of people$/ do |size|
	@app.people_downloader.images_for_people?(size,@app.people.people)
end

