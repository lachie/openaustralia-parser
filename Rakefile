require File.dirname(__FILE__)+'/lib/environment'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'spec/rake/spectask'

task :default => [:spec]

Spec::Rake::SpecTask.new do |t|
    t.ruby_opts = ['-rtest/unit']
    t.spec_files = FileList['spec/*_spec.rb', 'test/test_*.rb']
end

Spec::Rake::SpecTask.new(:spec_coverage) do |t|
    t.rcov = true
    t.rcov_opts = ["-x/Library/, -xspec"]
    t.ruby_opts = ['-rtest/unit']
    t.spec_files = FileList['spec/*_spec.rb', 'test/test_*.rb']
end


task :gems do
  module Kernel
    alias :gem_old :gem
    def gem(name,*version_requirements)
      begin
        gem_old(name,*version_requirements)
      rescue Gem::LoadError
        print "  [ ]"
      else
        print "  [I]"
      end
      puts "  %-20s %s" % [ name, version_requirements.inspect ]
    end
  end

  puts "checking gems"
  require 'lib/environment'

  module Kernel
    alias :gem :gem_old
  end
end

namespace :couch do
	task :config do
		@config = Configuration.new
	end

	task :db => :config do
		require 'couchrest'
    @db = CouchRest.database!(@config.couchdb_url)
	end

	def push_design(name,views,validate_doc_update)
		doc = begin
						@db.get("_design/#{name}")
					rescue RestClient::ResourceNotFound
						CouchRest::Design.new
					end
		doc.merge!(
			'language' => 'javascript',
			'views' => {}
		)
		doc.name = name

		views.each do |(name,functions)|
			next if functions.empty?

			v = doc['views'][name] = {}
			
			if map = functions['map']
				v['map'] = map.read
			end
			if reduce = functions['reduce']
				v['reduce'] = reduce.read
			end
		end

		if validate_doc_update
			doc['validate_doc_update'] = validate_doc_update.read
		end

		@db.save_doc(doc)
	end

	task :push_views => :db do
		root = Pathname.new(File.dirname(__FILE__)+'/couch_views')
		Dir["#{root}/*"].each do |design|
			design_path = Pathname.new(design)
			design_name = design_path.relative_path_from(root).to_s

			views = {}

			Dir["#{design_path}/*"].each do |view|
				view_path = Pathname.new(view)
				view_name = view_path.relative_path_from(design_path).to_s

				view = views[view_name] = {}

				map = view_path + 'map.js'
				view['map'] = map if map.exist?

				reduce = view_path + 'reduce.js'
				view['reduce'] = reduce if reduce.exist?

			end

			validate_doc_update = design_path + 'validate_doc_update.js'
			unless validate_doc_update.exist?
				validate_doc_update = nil
			end

			push_design(design_name,views,validate_doc_update)
		end
	end
end
