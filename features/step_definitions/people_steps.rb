Given /^a list of people "([^\"]*)"$/ do |name_list|
	@app.people.make!(name_list.split(/\s*,\s*/))
end

