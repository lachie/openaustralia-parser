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
    end

    def output!
      people          = @db.view_hash('people/by_twfy_id')
      registers_by_id = @db.view_hash('all/by_type', :key => 'register', :use_id => true)

      registers = people.inject({}) do |regs,(twfy_id,person)|
        pid = person['_id']
        rid = pid.sub(%r[^people/], 'register/')
        reg = registers_by_id[rid] || {}

        # debug, forces download!
        # reg.delete('pdf_etag')

        regs[twfy_id.to_i] = reg.update(
          '_id'    => rid,
          'type'   => 'register',
          'person' => pid
        )

        regs
      end

      @parser.parse(registers) do |register|
        pdf_path = register.delete('pdf_path')
        path     = File.dirname(pdf_path)

        puts "converting #{File.basename(pdf_path)} into images..."
        system("rm #{path}/*.jpg")
        system("convert -verbose -colorspace RGB -resize 800 -interlace none -density 300 -quality 50 #{pdf_path} #{path}/page.jpg")

        attachments = register['_attachments'] = {}
        Dir["#{path}/page*.jpg"].each do |jpg|
          puts "attaching #{jpg}"
          a = attachments[File.basename(jpg,'.jpg')] = {} 
          a['content_type'] = 'image/jpeg'
          a['data'] = Base64.encode64(File.read(jpg)).gsub(/\n/,'')
        end
      end

      puts "saving registers..."
      @db.bulk_save(registers.values)
    end
  end
end
