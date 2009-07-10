module Constituency
  class DbLoader
    def initialize(conf)
      @conf = conf
    end

    def setup!
      @db = Mysql.real_connect(@conf.database_host, @conf.database_user, @conf.database_password, @conf.database_name)
    end

    def validate!(data)
      puts "Reading members data..."
      people = PeopleCSVReader.read_members
      all_members = people.all_periods_in_house(House.representatives)

      # First check that all the constituencies are valid
      constituencies = data.map { |row| row[1] }.uniq
      constituencies.each do |constituency|
        raise "Constituency #{constituency} not found" unless all_members.any? {|m| m.division == constituency}
      end
    end

    def output(data)
      # Clear out the old data
      @db.query("DELETE FROM postcode_lookup")

      values = data.map {|row| "('#{row[0]}', '#{quote_string(row[1])}')" }.join(',')
      @db.query("INSERT INTO postcode_lookup (postcode, name) VALUES #{values}")
    end
  end
end
