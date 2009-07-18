require 'couchrest'
require 'pp'
require 'fileutils'

module Register
  class CouchLoader
    include FileUtils

    def initialize(conf,parser)
      @conf = conf
      @parser = parser
    end

    def setup!
      @db = CouchHelper.new(@conf)
      mkdir_p @conf.register_images_cache_path
    end

    def output!
      @people = @db.view_hash('people/by_twfy_id')
      @parser.parse do |params|
        _,id = *params[:filename].match(/register_interests_(\d+).pdf/)

        if person = @people[id.to_i]
          path     = File.join(@conf.register_images_cache_path,person['_id'])
          original = File.join(path,'original.pdf')
          mkdir_p(path)

          unless File.exist?(original)
            puts "saving original..."
            open(original,'w') {|f| f << params[:file]}
          end

          unless File.exist?("#{path}/page-0.jpg")
            puts "converting..."
            system("convert -verbose -colorspace RGB -resize 800 -interlace none -density 300 -quality 50 #{original} #{path}/page.jpg")
          end
        else
          puts "WARNING: no person found for twfy id #{id}"
        end
      end
    end
  end
end
