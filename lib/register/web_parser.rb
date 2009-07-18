module Register
  class WebParser
    def initialize(conf)
      @conf = conf
      @agent = MechanizeProxy.new
      @agent.cache_subdirectory = 'register'
    end

    def parse
      base_url = "http://www.openaustralia.org/regmem/scan/"
      @agent.get("#{base_url}/md5_scans").body.split("\n").each do |line|
        _,filename,md5 = *line.match(/MD5 \(([^\}]+)\) = ([a-z0-9]+)/)
        file = {:filename => filename, :md5 => md5}
        file[:file] = @agent.get("#{base_url}/#{filename}").body

        yield(file)
        break #debug
      end
    end
  end
end
