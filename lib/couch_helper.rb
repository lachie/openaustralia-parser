require 'couchrest'
require 'digest/sha1'
require 'set'

class CouchHelper
	def initialize(conf)
		@conf = conf
	end

	def db
		@db ||= CouchRest.database!(@conf.couchdb_url)
	end

	def bulk_save(docs,options={},&block)
		options = {
			:stride => 10
		}.merge(options)

		docs = docs.map {|doc|
			next unless doc

			sha1 = calculate_hash(doc)
			next if doc['_rev'] && doc['sha1'] == sha1
			doc['sha1'] = sha1

			doc
		}.compact
		
		stride = options.delete(:stride)
		puts "writing #{docs.size} docs in batches of #{stride}"

		i = 0
		docs.in_groups_of(stride,false) do |docs|

      docs.each(&block)

			from = i*stride
			puts "  #{from+1}..#{from+stride}"

			results = db.bulk_save(docs)

			handle_errors(results,docs,options)

			i += 1
		end
	rescue RestClient::RequestFailed
		puts "#{$!.class} : #{$!.message}"
		puts $!.response
		raise $! if options[:raise_on_error]
	end


	def handle_errors(results,docs,options)
		options = {:raise_on_error => true}.update(options)
		errors = Hash.new {|h,k| h[k] = {}}

		results.each do |res|
			error = res['error']
			next unless error

			errors[error][res['id']] = res['reason']
		end

		if !errors.blank?
			message = "some errors occurred while saving the docs [#{errors.keys * ', '}]"

			puts message
			pp errors

			if options[:show_conflicts]
				(errors['conflict'] || []).each do |(id,error)|
					puts
					puts "error: #{error}"
					doc = docs.find {|f| f['_id'] == id}
					pp doc
				end
			end

			if options[:raise_on_error]
				raise message
			end
		end
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
		when Numeric
			d << o.to_s
		when Date
			d << o.strftime("%F")
		when DateTime
			d << o.strftime("%FT%T")
		when Time
			d << o.strftime("%FT%T")
		else
			raise "unknown object #{o.class} : #{o.inspect}"
		end
	end

  def view_hash(name,options={})
    use_id = options.delete(:use_id)
    options[:include_docs] = true

    hash = {}
    view(name,options)['rows'].each do |row|
      hash[use_id ? row['id'] : row['key']] = row['doc']
    end
    hash
  end

  def method_missing(method,*args,&block)
    db.send(method,*args,&block)
  end
end
