require 'fileutils'

class PeopleXmlOutput
	attr_reader :conf
  def initialize(conf)
    @conf = conf
  end

  def setup!
    FileUtils.mkdir_p @conf.members_xml_path
  end

	def output(people)
		puts "Writing XML..."

		root = conf.members_xml_path
		people.write_xml("#{root}/people.xml", "#{root}/representatives.xml", "#{root}/senators.xml",
			"#{root}/ministers.xml", "#{root}/divisions.xml")
	end

	def finalise!
		# And load up the database
		# Starts with 'perl' to be friendly with Windows
		system("perl #{conf.web_root}/twfy/scripts/xml2db.pl --members --all --force")
	end

end
