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
    docs = @db.view('hansard/by_house_and_date',:key => [house.couch_id, date])['rows'].map do |r|
      {
        '_id' => r['id'],
        '_rev' => r['value'],
        '_deleted' => true
      }
    end

    unless docs.empty?
      puts "deleting existing hansard"
      pp docs
      deleted = @db.bulk_save(docs)
      pp deleted
    end
	end

  def finalise!(*args); end

	def output(debates,date,house)
		clear_date_for_house!(date,house)

		@speeches = []
		@speech_texts = []

		@docs = [{
			'_id' => ['hansard', 'federal', house.name, date.to_s(:db)].to_key,
      :level => 'federal',
			:author => @author,
			:date => date,
			:house => house.couch_id,
			:type => 'hansard',
      'hansard-tree' => true
		}]

		@last_major = nil
		@last_minor = nil

		debates.items.each do |item|
			# we don't handle these yet!
			next if Division === item

			case item
			when MajorHeading
				@docs << @last_major = output_major_heading(item)
			when MinorHeading
				@docs << @last_minor = output_minor_heading(item)
			when Speech
				speech_doc,speech_text = output_speech(item)

				@speeches     << speech_doc
				@speech_texts << speech_text
			end
		end

		begin
      puts "saving #{@docs.size} docs"
      @docs.in_groups_of(10) {|docs|
        docs.compact!
        @db.bulk_save(docs) if docs && !docs.empty?
      }
		rescue RestClient::RequestFailed
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
																	:house => speech.house.couch_id,
																	:date => speech.date,
																	:time => speech.time,
																	:type => 'speech',
                                  'hansard-tree' => true
																 )
		
		speaker = speech.speaker

		case speaker
		when Period
			doc[:speaker] = speaker.person.couch_id
			doc[:speaker_name] = speaker.person.name.to_hash
		when UnknownSpeaker
			doc[:speaker] = speaker.couch_id
			doc[:speaker_name] = speaker.name.to_hash
			doc['unknown-speaker'] = true
    else
      doc[:speaker] = "people/none"
      doc[:speaker_name] = {
        :first => "No", :last => "Speaker"
      }
			doc['unknown-speaker'] = true
		end

    doc[:section] = section = speech.count.to_f
    doc[:path]    = [ @last_minor[:path], section ].flatten

		[doc,speech.content.to_s]
	end

  def output_heading(heading)
    section = heading.count.to_f 
		{
      :title => heading.title,
      '_id' => heading.couch_id,
      :date => heading.date,
      :house => heading.house.couch_id,
      :path => [section],
      :section => section,
      'hansard-tree' => true
    }
  end

	def output_major_heading(heading)
    doc = output_heading(heading)
    doc[:type] = 'major-heading'
    doc
  end

	def output_minor_heading(heading)
    doc = output_heading(heading)

    doc[:type] = 'minor-heading'

    doc[:path] = [@last_major[:path]] + doc[:path]
    doc[:path].flatten!

    doc
	end
end
