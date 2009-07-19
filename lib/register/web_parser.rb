require 'fileutils'
require 'mechanize'

module Register
  class WebParser
    include FileUtils

    def initialize(conf)
      @conf = conf
      @agent = WWW::Mechanize.new
      # @agent.cache_subdirectory = 'register'
    end

    def parse(registers)
      base_url = "http://www.openaustralia.org/regmem/scan/"

        puts "fetching info..."
        @agent.get("#{base_url}/").search('//a').each do |a|
          original_url = a['href']
          next unless original_url[/pdf$/]

          head = @agent.head(original_url)
          etag = head.response['etag']


          _,twfy_id = *original_url.match(/register_interests_(\d+).pdf$/)
          twfy_id = twfy_id.to_i

          register = registers[twfy_id]


          filename = File.basename(original_url)
          if register['pdf_etag'] == etag
            puts "#{filename} etag unchanged, skipping..."
            next
          end

          register['pdf_etag'] = etag

          path     = File.join(@conf.register_images_cache_path,register['person'])
          original = File.join(path,'original.pdf')
          mkdir_p(path)

          puts "downloading pdf #{filename}..."
          #open(original,'w') {|f| f << }
          @agent.get(original_url).save_as(original)

          register['pdf_path'] = original

          yield(register)
          break #debug
      end
    end
  end
end
