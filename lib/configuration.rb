require 'yaml'
require 'activesupport'
require 'pp'

class Configuration
  # TODO: Could have conflicts between these and names in the configuration file
  attr_reader :database_host, :database_user, :database_password, :database_name, :file_image_path, :members_xml_path, :xml_path,
    :regmem_pdf_path, :base_dir
  
  cattr_accessor :local_config_path
  cattr_accessor :root

  # Load the configuration
  def self.global_conf
    unless @conf
      root = self.root = File.expand_path(File.dirname(__FILE__)+'/..')

      @conf = YAML.load_file( "#{root}/configuration.yml" ) || {}

      local_config = self.local_config_path ||= "#{root}/configuration-local.yml"
      if File.exist?(local_config)
        @conf.merge!( YAML.load_file( local_config ) )
      end

      subs = {
        ':root' => root,
        ':home' => ENV['HOME']
      }

      @conf.each do |(key,value)|
        if String === value
          @conf[key] = value.gsub(/:[a-z]+/) do |key|
						if sub = subs[key]
							sub
						else
							key
						end
					end
        end
      end
    end

    @conf
  end
  def global_conf; self.class.global_conf end

  def self.clear_global_conf!
    @conf = nil
  end
  
  def initialize
    begin
      # Load the information from the mysociety configuration
      require "#{web_root}/rblib/config"

      MySociety::Config.set_file("#{web_root}/twfy/conf/general")

      {
        'database_host'     => 'DB_HOST',
        'database_password' => 'DB_PASSWORD',
        'database_name'     => 'DB_NAME',
        'file_image_path'   => 'FILEIMAGEPATH',
        'members_xml_path'  => 'PWMEMBERS',
        'xml_path'          => 'RAWDATA',
        'regmem_pdf_path'   => 'REGMEMPDFPATH',
        'base_dir'          => 'BASEDIR',
      }.each do |(ivar,key)|
        value = if global_conf.key?(ivar)
                  global_conf[ivar]
                else
                  MySociety::Config.get(key)
                end

        instance_variable_set("@#{ivar}", value)
      end

    rescue LoadError
      puts "WARNING: twfy/my society config not loaded (#{$!})"
    end
  end

  # Ruby magic
  def method_missing(method_id)
    name = method_id.id2name
    if global_conf.has_key?(name)
      global_conf[name]
    else
      super
    end
  end
end
