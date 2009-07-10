require 'couchrest'

module Constituency
  class CouchLoader
    def initialize(conf)
      @conf = conf
    end

    def setup!
      @db = ::CouchRest.database!(@conf.couchdb_url)
    end

    def validate!(data)
    end

    def output(data)
      lookup = Hash.new {|h,k| h[k] = []}
      keys = []
      data.each {|line|
        keys << key = ['constituencies','federal',line[1]].to_key 
        lookup[key] << line[0]
      }

      docs = @db.documents(:keys => keys, :include_docs => 'true')['rows'].map do |row|
        row['doc']['postcodes'] = lookup[row['id']].uniq.sort
        row['doc']
      end

      stride = 100
      (docs.size / stride).times do |i|
        from = i * stride
        to   = from + stride - 1
        puts "saving #{from}..#{to}"
        @db.bulk_save(docs[from..to])
      end
    end
  end
end
