require 'couchrest'

class PeopleCouchLoader
  class << self
    def load(people)
      new(people).load
    end
  end

  def initialize(people)
    @people = people
    @db = CouchRest.database!("http://127.0.0.1:5984/openaustralia")
    # TODO remove later
    @db.recreate!
  end

  def load
    load_people
  end

  def write_doc(key,doc_hash)
    doc_hash['_id'] = key

    begin
      doc = @db.get(key)
      doc.destroy
    rescue RestClient::ResourceNotFound
    end

    begin
      resp = @db.save_doc(doc_hash)
    rescue
      pp $!.response.body
      raise $!
    end
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
      slug = to_key(person.name.full_name)
      key = ['people',slug] * '/'
      @db.save_doc(compact_hash('_id' => key,
        :aph_id => person.aph_id,
        :birthday => person.birthday,
        :type => 'person',
        :name => person.name.to_hash,
        :alternative_names => person.alternate_names.map {|a| a.to_hash}
     ))

     load_people_positions(person,key,slug)
     load_people_periods(person,key,slug)
    end
  end

  def load_people_positions(person,person_key,person_slug)
    @slugs ||= Hash.new {|h,k| h[k] = -1}

    person.minister_positions.each do |pos|
      pos_doc = load_position(pos)

      key = ['people-positions','federal',pos.minister_count] * '/'

      pp = compact_hash(
        '_id'     => key,
        :type     => 'person-position',
        :name     => pos.position,
        :position => pos_doc['id'],
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

  def load_position(pos)
    slug = to_key(pos.position)
    key  = ['positions','federal',slug] * '/'
    @positions ||= {}

    if doc = @positions[key]
      return doc
    end

    doc = CouchRest::Document.new('_id' => key,
                                  :name => pos.position,
                                  :slug => slug,
                                 :type => 'position')
    @db.save_doc(doc)
    @positions[key] = doc
  end
  
  def load_people_periods(person,person_key,person_slug)
    person.periods.each do |period|
      key = ['people-period','federal',period.id_for_house] * '/'

      div   = load_division(period.division, period.state)
      party = load_party(period.party)
      house = load_house(period.house)

      pp = compact_hash( 
        '_id'         => key,
        :person       => person_key,

        :type         => 'person-period',

        :division     => div['id'],

        :state        => period.state,
        :party        => party['id'],
        :house        => house['id'],

        :entry_date   => period.from_date,
        :entry_reason => period.from_why,

        :exit_date    => period.to_date,
        :exit_reason  => period.to_why
      )

      @db.save_doc(pp)
    end
  end

  def load_division(name,state)
    @divisions ||= {}

    key = ['divisions','federal',to_key(state)]
    if !name.blank?
      key << to_key(name)
    end
    key = key * '/'

    if div = @divisions[key]
      return div
    end

    div = compact_hash('_id' => key,
                       :type => 'division',
                       :name => name,
                       :state => state
                      )

    @divisions[key] = @db.save_doc(div)
  end

  def load_party(party)
    @parties ||= {}
    key = ['parties','federal',to_key(party)] * '/'

    if party = @parties[key]
      return party
    end

    party = compact_hash('_id' => key,
                         :name => party,
                         :type => 'party'
                        )

    @parties[key] = @db.save_doc(party)
  end

  def load_house(house)
    @houses ||= {}
    key = ['houses','federal',to_key(house)] * '/'

    if house = @houses[key]
      return house
    end

    house = compact_hash('_id' => key,
                         :name => house,
                         :type => 'house')
    @houses[key] = @db.save_doc(house)
  end

# people = [people.first]


# divs = members.map do |member|
#   [member.division, member.state]
# end.uniq.each do |division|
#   key = ["divisions",'federal','reps',division.last.downcase,division.first.downcase.gsub(/[^a-z]+/,'-')] * '/'
#   puts key
# end
# 
# 
# members.each do |member|
#   # pp member
# end

#people.each do |person|
#  key = person.name.full_name.downcase.gsub(/[^a-z]+/,'-')
#  puts key
#end

#pp people[0..10]
end
