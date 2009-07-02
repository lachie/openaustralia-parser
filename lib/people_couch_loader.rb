require 'couchrest'

class PeopleCouchLoader
  def initialize(conf)
    @conf = conf
  end

  def setup!
    @db = CouchRest.database!("http://127.0.0.1:5984/openaustralia")
    # TODO remove later
    @db.recreate!
  end

  def finalise!; end

  def output(people)
    @people = people

    load_people
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

      @db.save_doc(compact_hash('_id' => key,
        :aph_id => person.aph_id,
        :birthday => person.birthday,
        :type => 'person',
        :name => person.name.to_hash,
        :alternative_names => person.alternate_names.map {|a| a.to_hash}
     ))

     load_people_positions(person,key)
     load_people_periods(person  ,key)
    end
  end

  def load_people_positions(person,person_key)
    @slugs ||= Hash.new {|h,k| h[k] = -1}

    person.minister_positions.each do |pos|
      key = ['people-positions','federal',pos.minister_count] * '/'

      pp = compact_hash(
        '_id'     => key,
        :type     => 'person-position',
        :name     => pos.position,
        :position => position_key(pos),
        :person   => person_key,
        :from     => pos.from_date,
        :to       => pos.to_date
      )

      if pp[:to].year == 9999
        pp.delete(:to)
      end

      @db.save_doc(pp)
    end
  end

  def position_key(pos)
    ['positions','federal',to_key(pos.position)] * '/'
  end

  def load_people_periods(person,person_key)
    person.periods.each do |period|
      key = ['people-period','federal',period.id_for_house] * '/'

      div   = load_division(period.division, period.state)
      party = load_party(period.party)
      house = load_house(period.house)

      pp = compact_hash( 
        '_id'         => key,
        :person       => person_key,

        :type         => 'person-period',

        :division     => div,

        :state        => period.state,
        :party        => party,
        :house        => house,

        :entry_date   => period.from_date,
        :entry_reason => period.from_why,

        :exit_date    => period.to_date,
        :exit_reason  => period.to_why
      )

      @db.save_doc(pp)
    end
  end

  def division_key(name,state)
    key = ['divisions','federal',to_key(state)]

    if !name.blank?
      key << to_key(name)
    end

    key * '/'
  end

  def load_division(name,state)
    compact_hash(:key => division_key(name,state),
                 :name => name,
                 :state => state
                )
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
