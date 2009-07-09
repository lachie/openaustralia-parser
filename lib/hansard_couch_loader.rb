require 'couchrest'

class HansardCouchLoader
	def initialize(conf)
		@conf = conf
		@author = 'lachie'
	end

	def setup!
    @db = CouchRest.database!(@conf.couchdb_url)

	end

	# clear out hansard stuff that we want to reload now
	def clear_date_for_house!(date,house)
    docs = @db.view('hansard/by_house_and_date',:key => [house.name.to_key, date].to_json)['rows'].map do |r|
      {
        '_id' => r['id'],
        '_rev' => r['value'],
        '_deleted' => true
      }
    end

    unless docs.empty?
      puts "deleting existing hansard"
      deleted = @db.bulk_save(docs)
      pp deleted
    end
	end

  def finalise!(*args); end

	def output(debates,date,house)
		clear_date_for_house!(date,house)

		@speeches = []
		@speech_texts = []

		doc = {
			'_id' => ['hansard','federal',house.name,date.to_s(:db)].to_key,
			:author => @author,
			:date => date,
			:house => house.name.to_key,
			:type => 'hansard',
			:tree => []
		}

		tree = doc[:tree]
		@last_major = nil
		@last_minor = nil

		debates.items.each do |item|
			# we don't handle these yet!
			next if Division === item

			case item
			when MajorHeading
				tree << @last_major = output_major_heading(item)
			when MinorHeading
				@last_major[:children] << @last_minor = output_minor_heading(item)
			when Speech
				speech_doc,speech_text = output_speech(item)

				@speeches     << speech_doc
				@speech_texts << speech_text

				@last_minor[:children] << speech_doc.id
			end
		end

		begin
			unless doc[:tree].empty?
				@db.save_doc(doc)
			end
		rescue RestClient::RequestFailed
			pp doc
			puts "failed: #{$!.response}"
			puts "hmm: #{$!.response.body}"
		end

		begin
			unless @speeches.empty?
				puts "saving #{@speeches.size} speeches"

				stride = 10
				(@speeches.size / stride).times do |i|
					from = i * stride
					to   = from + stride - 1
					puts "saving speeches #{from}..#{to}"

					loaded = @db.bulk_save( @speeches[from..to] )

					puts "attaching text"
					(from..to).each_with_index do |index,base_index|
						speech = loaded[base_index]
						speech_doc = {'_rev' => speech['rev'], '_id' => speech['id']}
						@db.put_attachment(speech_doc,'text',@speech_texts[index])
					end
				end
			end
		rescue RestClient::RequestFailed
			puts "failed: #{$!.response}"
			puts "hmm: #{$!.response.body}"
		end

	end

	def output_speech(speech)
		doc = CouchRest::Document.new( '_id' => speech.couch_id,
																	:author => @author,
																	:house => speech.house.name.to_key,
																	:date => speech.date,
																	:time => speech.time,
																	:type => 'speech'
																 )
		
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

		[doc,speech.content.to_s]
	end

	def output_major_heading(heading)
		{:title => heading.title, :key => heading.couch_id, :children => []}
	end

	def output_minor_heading(heading)
		{:title => heading.title, :key => heading.couch_id, :children => []}
	end
end
