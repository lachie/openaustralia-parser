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
      people          = @db.view_hash('people/by_twfy_id')
      registers_by_id = @db.view_hash('all/by_type', :key => 'register', :use_id => true)

      registers = people.inject({}) do |regs,(twfy_id,person)|
        pid = person['_id']
        rid = pid.sub(%r[^people/], 'register/')
        reg = registers_by_id[rid] || {}

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
        system("convert -verbose -colorspace RGB -resize 800 -interlace none -density 300 -quality 50 #{pdf_path} #{path}/page.jpg")
      end

      puts "saving registers..."
      @db.bulk_save(registers.values)
    end
  end
end
