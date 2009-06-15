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
          @conf[key] = value.gsub(/:[a-z]+/) {|key| subs[key] }
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
    # Load the information from the mysociety configuration
    require "#{web_root}/rblib/config"

    MySociety::Config.set_file("#{web_root}/twfy/conf/general")

    @database_host     = MySociety::Config.get('DB_HOST')
    @database_user     = MySociety::Config.get('DB_USER')
    @database_password = MySociety::Config.get('DB_PASSWORD')
    @database_name     = MySociety::Config.get('DB_NAME')
    @file_image_path   = MySociety::Config.get('FILEIMAGEPATH')
    @members_xml_path  = MySociety::Config.get('PWMEMBERS')
    @xml_path          = MySociety::Config.get('RAWDATA')
    @regmem_pdf_path   = MySociety::Config.get('REGMEMPDFPATH')
    @base_dir          = MySociety::Config.get('BASEDIR')
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
