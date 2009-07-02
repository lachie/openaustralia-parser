require 'fileutils'

class HansardXmlWriter
	def initialize(config)
		@conf = config
	end

	def setup!
		FileUtils.mkdir_p "#{@conf.xml_path}/scrapedxml/representatives_debates"
		FileUtils.mkdir_p "#{@conf.xml_path}/scrapedxml/senate_debates"
	end
	
	def finalise!(options={})
		command_options = " --from=#{options[:from_date]} --to=#{options[:to_date]}"
		command_options << " --debates" if @conf.write_xml_representatives
		command_options << " --lordsdebates" if @conf.write_xml_senators
		command_options << " --force" if options[:force]
		
		# Starts with 'perl' to be friendly with Windows
		system("perl #{@conf.web_root}/twfy/scripts/xml2db.pl #{command_options}")
	end

	def output(debates,date,house)
		if debates.content?
			xml_filename = "#{@conf.xml_path}/scrapedxml/#{house.name}_debates/#{date}.xml"
			debates.output(xml_filename)
		end
	end
end
