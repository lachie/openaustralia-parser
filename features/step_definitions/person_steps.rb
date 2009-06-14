Given /^a person "([^\"]*)"$/ do |name|
  @app.person.make!(name)
end
