require 'couchrest'

class Person
	class LinkCouchLoader
		def initialize(conf,people)
			@conf = conf
			@people = people
		end

		def setup!
			@writers = []
			@db = CouchRest.database!(@conf.couchdb_url)

			@people_lookup = {}
			@people_docs = []

			puts "fetching people"
			@db.view('all/by_type',:key => 'person', :include_docs => true)['rows'].each do |row|
				@people_docs << doc = row['doc']
				@people_lookup[doc['_id']] = doc

				doc['links'] ||= {}
			end

			[
				[ Person::TweetmpParser , Person::TweetmpCouchLoader  ],
				[ Person::WebsitesParser, Person::WebsitesCouchLoader ],
				[ Person::QandaParser   , Person::QandaCouchLoader    ]
			].each {|(parser_class,writer_class)|
				parser = parser_class.new(@conf,@people)
				@writers << writer = writer_class.new(@conf,parser,@people_lookup)
				writer.setup!
			}

		end

		def output
			@writers.each do |w|
				puts "reading #{w.class}"
				w.output
			end
		end

		def finalise!
			puts "writing docs..."
			CouchHelper.new(@conf).bulk_save(@people_docs)
		end
	end
end

