require 'couchrest'

class HansardCouchLoader
	def initialize(conf)
		@conf = conf
	end

	def setup!
    @db = CouchRest.database!("http://127.0.0.1:5984/openaustralia")
    # TODO remove later
    @db.recreate!
	end

  def finalise!(*args); end

	def output(debates,date,house)
		debates.items.each do |item|

			next if Division === item

			doc = {
				'_id' => item.couch_id,
				:date => item.date
			}

			case item
			when MajorHeading
				output_major_heading(item,doc)
			when MinorHeading
				output_minor_heading(item,doc)
			when Speech
				output_speech(item,doc)
			end

			@db.save_doc(doc)
		end
	end

	def output_speech(speech,doc)
		doc.merge! :time => speech.time, :type => 'speech', :content => speech.content.to_s
		
		speaker = speech.speaker
		case speaker
		when Period
			doc[:speaker] = speaker.person.couch_id
			doc[:speaker_name] = speaker.person.name.to_hash
		when UnknownSpeaker
			doc[:speaker] = speaker.couch_id
			doc[:speaker_name] = speaker.name.to_hash
			doc[:unknown_speaker] = true
		end
	end

	def output_major_heading(heading,doc)
		doc.merge! :title => heading.title, :type => 'major-heading'
	end

	def output_minor_heading(heading,doc)
		doc.merge! :title => heading.title, :type => 'minor-heading'
	end
end
