require 'couchrest'

class PeopleCouchLoader
  def initialize(conf)
    @conf = conf
    @author = 'lachie'
    @count = 0
  end

  def setup!
    @db = CouchRest.database!(@conf.couchdb_url)

    docs = @db.view('people/all')['rows'].map do |r|
      {
        '_id' => r['id'],
        '_rev' => r['value'],
        '_deleted' => true
      }
    end

    unless docs.empty?
      puts "deleting existing people"
      deleted = @db.bulk_save(docs)
      pp deleted
    end
  end

  def finalise!; end

  def add_doc(doc)
    @docs ||= []
    @docs << doc

    #@db.save_doc(doc)
    #puts "  #{@count}" if @count % 10 == 0
    #@count += 1
  end

  def output(people)
    @people = people

    puts "creating people docs..."
    puts "   and saving people docs..."
    load_people

    stride = 100
    (@docs.size / stride).times do |i|
      from = i * stride
      to   = from + stride - 1
      puts "saving #{from}..#{to}"
      @db.bulk_save(@docs[from..to])
    end

  rescue RestClient::RequestFailed
    puts "failed: #{$!.response}"
    pp $!.response.headers
    puts "hmm: #{$!.response.body}"
  end

  def compact_hash(hash)
    hash.inject({}) do |h,(k,v)|
      h[k] = v if !v.blank?
      h
    end
  end

  def to_key(*key)
    key.join(' ').downcase.gsub(/[^a-z]+/,'-')
  end

  def load_people
    @people.each do |person|
      key = person.couch_id

      pdoc = compact_hash('_id' => key,
        :author => @author,
        :aph_id => person.aph_id,
        :birthday => person.birthday,
        :type => 'person',
        :name => person.name.to_hash,
        :alternative_names => person.alternate_names.map {|a| a.to_hash}
      )

      if (current_positions = load_people_positions(person,key)) && !current_positions.empty?
        pdoc[:current_positions] = current_positions.map {|p|
          {:key => p['_id'], :name => p[:name]}
        }
      end

      if (current_constituencies = load_people_periods(person,key)) && !current_constituencies.empty?
        pdoc[:current_constituencies] = current_constituencies.map {|p|
          {:key => p['_id'], :name => p[:name], :constituency => p[:constituency]}
        }
      end

      add_doc(pdoc)
    end
  end

  def load_people_positions(person,person_key)
    current_positions = []

    person.minister_positions.each do |pos|
      key = ['people-positions','federal',pos.minister_count] * '/'

      pp = compact_hash(
        '_id'     => key,
        :author => @author,
        :type     => 'person-position',
        :name     => pos.position,
        :position => position_key(pos),
        :person   => person_key,
        :from     => pos.from_date,
        :to       => pos.to_date
      )

      current_positions << pp if pos.current?

      if pp[:to].year == 9999
        pp.delete(:to)
      end

      add_doc(pp)
    end

    current_positions
  end

  def position_key(pos)
    ['positions','federal',to_key(pos.position)] * '/'
  end

  def load_people_periods(person,person_key)
    current_constituencies = []

    person.periods.each do |period|

      key = ['people-period','federal',period.id_for_house] * '/'


      div   = load_constituency(period.division, period.state)
      party = load_party(period.party)
      house = load_house(period.house)

      pp = compact_hash( 
        '_id'         => key,
        :author       => @author,
        :person       => person_key,

        :type         => 'person-period',

        :constituency => div['_id'],

        :name         => (period.division || period.state),

        :state        => period.state,
        :party        => party,
        :house        => house,

        :entry_date   => period.from_date,
        :entry_reason => period.from_why,

        :exit_date    => period.to_date,
        :exit_reason  => period.to_why
      )

      current_constituencies << pp if period.current?
      
      add_doc(pp)
    end

    current_constituencies
  end

  def constituency_key(name,state)
    ['constituencies','federal',to_key(name || state)].to_key
  end

  def load_constituency(name,state)
    p = compact_hash(
                 '_id' => constituency_key(name,state),
                 :name => (name || state),
                 :state => state,
                 :type => 'constituency'
                )
    add_doc(p)
    p
  end

  def party_key(party)
    ['parties','federal',to_key(party)] * '/'
  end

  def load_party(party)
    {
      :name => party,
      :key => party_key(party)
    }
  end

  def house_key(house)
    ['houses','federal',to_key(house)] * '/'
  end
  def load_house(house)
    {
      :name => house,
      :key => house_key(house)
    }
  end
end
