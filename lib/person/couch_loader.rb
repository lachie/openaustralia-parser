require 'couchrest'

class Person
	class CouchLoader
		def initialize(conf)
			@conf = conf
			@author = 'lachie'
			@count = 0
		end

		def setup!
			@db = CouchRest.database!(@conf.couchdb_url)

			@lookup = {}

			@db.view('people/all', :include_docs => true)['rows'].each do |r|
				@lookup[r['id']] = r['doc']
			end
		end

		def finalise!; end


		def output(people)
			@people = people

			puts "creating people docs..."
			load_people

			puts "saving people docs..."
			CouchHelper.new(@conf).bulk_save(@lookup.values)
		end

		def compact_hash(hash)
			hash.inject({}) do |h,(k,v)|
				h[k] = v if !v.blank?
				h
			end
		end

		def load_people
			@people.each do |person|

				person_key = person.couch_id
				doc = @lookup[person_key] ||= {}

				doc.merge!(
					'_id'               => person_key,
					'author'            => @author,
					'aph_id'            => person.aph_id,
					'birthday'          => person.birthday,
					'type'              => 'person',
					'name'              => person.name.to_hash,
					'alternative_names' => person.alternate_names.map {|a| a.to_hash}
				)

				
				current_positions = load_people_positions(person,person_key)
				unless current_positions.blank?
					doc[:current_positions] = current_positions.map {|p|
						{
							'key'  => p['_id'],
							'name' => p['name']
						}
					}
				end

				current_constituencies,current_party = load_people_periods(person,person_key)

				if !current_constituencies.blank?
					doc['current_constituencies'] = current_constituencies.map {|p|
						{
							'key'          => p['_id'],
							'name'         => p['name'],
							'constituency' => p['constituency'],
							'party'        => p['party']['name'],
							'party_key'    => p['party']['key'],
						}
					}
				end

				if current_party
					doc['current_party'] = current_party
				end

			end
		end

		def load_people_positions(person,person_key)
			current_positions = []

			person.minister_positions.each do |pos|
				key = ['people-positions','federal',pos.minister_count.to_s].to_key
				doc = @lookup[key] ||= {}

				position_key = ['positions','federal',pos.position].to_key

				doc.merge!(
					'_id'      => key,
					'author'   => @author,
					'type'     => 'person-position',
					'name'     => pos.position,
					'position' => position_key,
					'person'   => person_key,
					'from'     => pos.from_date,
					'to'       => pos.to_date
				)

				current_positions << doc if pos.current?

				if doc['to'] && doc['to'].year == 9999
					doc.delete('to')
				end
			end

			current_positions
		end


		def load_people_periods(person,person_key)
			current_constituencies = []
			current_party = nil

			person.periods.each do |period|

				key = ['people-period','federal',period.id_for_house.to_s].to_key
				doc = @lookup[key] ||= {}

				div   = load_constituency(period.division, period.state)
				party = load_party(period.party)

				doc.merge!( 
					'_id'          => key,
					'author'       => @author,
					'person'       => person_key,

					'type'         => 'person-period',

					'constituency' => div['_id'],

					'name'         => (period.division || period.state),

					'state'        => period.state,
					'party'        => party,
					'house'        => period.house.couch_id,

					'entry_date'   => period.from_date,
					'entry_reason' => period.from_why,

					'exit_date'    => period.to_date,
					'exit_reason'  => period.to_why
				)


				if period.current?
					current_constituencies << doc
					current_party = party
				end
			end

			[current_constituencies,current_party]
		end

		def load_constituency(name,state)
			name ||= state
			key = ['constituencies','federal',name].to_key

			doc = @lookup[key] ||= {}
			doc.merge!(
									 '_id'   => key,
									 'name'  => name,
									 'state' => state,
									 'type'  => 'constituency'
									)
			doc
		end

		def load_party(party)
			party_key = ['parties','federal',party].to_key
			{
				'name' => party,
				'key'  => party_key
			}
		end
	end
end
