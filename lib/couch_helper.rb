require 'couchrest'
require 'digest/sha1'

class CouchHelper
	def initialize(conf)
		@conf = conf
	end

	def db
		@db ||= CouchRest.database!(@conf.couchdb_url)
	end

	def bulk_save(docs,options={})
		options = {
			:stride => 10
		}.merge(options)

		docs = docs.map {|doc|
			next unless doc

			if doc['_rev']
				new_hash = calculate_hash(doc)
				next if doc['sha1'] == new_hash
				doc['sha1'] = new_hash
			end

			doc
		}.compact
		
		stride = options.delete(:stride)
		puts "writing #{docs.size} docs in batches of #{stride}"

		i = 0
		docs.in_groups_of(stride,false) do |docs|
			from = i*stride
			puts "  #{from+1}..#{from+stride}"
			db.bulk_save(docs)
			i += 1
		end
	rescue RestClient::RequestFailed
		puts "#{$!.class} : #{$!.message}"
		puts $!.response
	end

	def calculate_hash(doc)
		d = Digest::SHA1.new
		_calc_hash(d,doc,:top)
		d.to_s
	end

	def _calc_hash(d,o,level=nil)
		case o
		when Hash
			o.keys.sort {|a,b| a.to_s <=> b.to_s}.each do |key| 
				next if level == :top && (key == 'sha1' || key == '_rev')
				d << key.to_s
				_calc_hash(d,o[key])
			end
		when Array
			o.each {|e| _calc_hash(d,e)}
		when String
			d << o
		when TrueClass
			'true'
		when FalseClass
			'false'
		when NilClass
		when Date
			o.strftime("%F")
		when DateTime
			o.strftime("%FT%T")
		when Time
			o.strftime("%FT%T")
		else
			raise "unknown object #{o.class} : #{o.inspect}"
		end
	end
end
