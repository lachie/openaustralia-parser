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

      mkdir_p @conf.register_images_cache_path

      # debug
      #reg = registers[10001]
      #reg['pdf_path'] = File.join(@conf.register_images_cache_path,"people/tony-john-abbott",'original.pdf')
      #yield(reg)

      #return

      puts "fetching info..."
      @agent.get("#{base_url}/").search('//a').each do |a|
        original_url = a['href']
        next unless original_url[/pdf$/]

        # do a HEAD on the pdf to find the etag
        head = @agent.head(original_url)
        etag = head.response['etag']


        # find the register by twfy_id
        _,twfy_id = *original_url.match(/register_interests_(\d+).pdf$/)
        twfy_id = twfy_id.to_i

        register = registers[twfy_id]

        filename = File.basename(original_url)


        # test the fetched etag against the existing etag
        if register['pdf_etag'] == etag
          puts "#{filename} etag unchanged, skipping..."
          next
        end

        register['pdf_etag'] = etag

        base_path = register['person'].to_key
        path     = File.join(@conf.register_images_cache_path,base_path)
        rm_rf(path) rescue nil
        mkdir_p(path)

        original = File.join(path,'original.pdf')

        puts "downloading pdf #{filename}..."
        @agent.get(original_url).save_as(original)

        register['pdf_path'] = original

        yield(register)
      end
    end
  end
end
