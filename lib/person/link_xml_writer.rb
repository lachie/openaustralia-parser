class Person
class LinkXmlWriter
	def initialize(conf,people)
		@conf = conf
		@people = people
	end

	def setup!
		@writers = []

		[
			[ Person::TweetmpParser , Person::TweetmpXmlWriter  ],
			[ Person::WebsitesParser, Person::WebsitesXmlWriter ],
			[ Person::QandaParser   , Person::QandaXmlWriter    ]
		].each {|(parser_class,writer_class)|
			parser = parser_class.new(@conf,@people)
			@writers << writer = writer_class.new(@conf,parser)
			writer.setup!
		}
	end

	def output
		@writers.each do |w|
			puts w.class
			w.output
		end
	end

	def finalise!
		system(@conf.web_root + "/twfy/scripts/mpinfoin.pl links")
	end
end
end
