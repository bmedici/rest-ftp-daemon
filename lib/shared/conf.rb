require "chamber"

module Shared

  # FIXME: files named with hyphens will not be found by Chamber for now
  class ConfigMissingParameter    < StandardError; end
  class ConfigOtherError          < StandardError; end
  class ConfigParseError          < StandardError; end
  class ConfigMultipleGemspec     < StandardError; end
  class ConfigMissingGemspec      < StandardError; end

  class Conf
    extend Chamber

    class << self
      attr_accessor :app_env

      attr_reader :app_root
      attr_reader :app_libs

      attr_reader :app_name
      attr_reader :app_ver
      attr_reader :app_started

      attr_reader :spec
      attr_reader :files
      attr_reader :host
    end

    def self.init app_root = nil
      # Defaults, hostname
      @files        = []
      @app_env      = "production"
      @app_started  = Time.now
      @host         = `hostname`.to_s.chomp.split(".").first

      # Grab app root
      @app_root = File.expand_path( File.dirname(__FILE__) + "/../../")

      # Try to find any gemspec file
      matches   = Dir["#{@app_root}/*.gemspec"]
      fail ConfigMissingGemspec, "gemspec file not found: #{gemspec_path}" if matches.size < 1
      fail ConfigMultipleGemspec, "gemspec file not found: #{gemspec_path}" if matches.size > 1

      # Load Gemspec (just the only match)
      @spec     = Gem::Specification::load(matches.first)
      @app_name = @spec.name
      @app_ver  = @spec.version
      fail ConfigMissingParameter, "gemspec: missing name" unless @app_name
      fail ConfigMissingParameter, "gemspec: missing version" unless @app_ver

      # Now we know app_name, initalize app_libs
      @app_libs = File.expand_path( @app_root + "/lib/#{@app_name}/" )

      # Add other config files
      add_default_config
      add_etc_config
    end

    def self.prepare args = {}
      # Add extra config file
      add_extra_config args[:config]

      # Load configuration files
      load_files

      # Init New Relic
      prepare_newrelic self[:newrelic], self.at(:logs, :newrelic)

      # Try to access any key to force parsing of the files
      self[:dummy]

    rescue Psych::SyntaxError => e
      fail ConfigParseError, e.message
    rescue StandardError => e
      fail ConfigOtherError, "#{e.message} \n #{e.backtrace.to_yaml}"
    end

    def self.reload!
      load_files
    end

    def self.dump
      to_hash.to_yaml(indent: 4, useheader: true, useversion: false )
    end

    # Direct access to any depth
    def self.at *path
      path.reduce(Conf) { |m, key| m && m[key.to_s] }
    end

    def self.newrelic_enabled?
      !!self[:newrelic]
    end

  protected

    def self.load_files
      load files: @files, namespaces: { environment: @app_env }
    end

    def self.add_default_config
      @files << "#{@app_root}/defaults.yml" if @app_root
    end

    def self.add_etc_config
      @files << File.expand_path("/etc/#{@app_name}.yml") if @app_name
    end

    def self.add_extra_config path
      @files << File.expand_path(path) if path
    end

    def self.get_pidfile
      self[:pidfile] || "/tmp/#{@app_name}-#{@host}-#{self[:port]}.pid"
    end

    def self.prepare_newrelic section, logfile
      # Disable NewRelic if no config present
      unless section.is_a?(Hash) && section[:licence]
        ENV["NEWRELIC_AGENT_ENABLED"] = "false"
        return
      end

      # Enable GC profiler
      GC::Profiler.enable

      # Enable module
      ENV["NEWRELIC_AGENT_ENABLED"] = "true"
      ENV["NEW_RELIC_MONITOR_MODE"] = "true"

      # License
      ENV["NEW_RELIC_LICENSE_KEY"] = section[:licence].to_s

      # Appname
      platform = section[:platform] || self.host
      section[:app_name] ||= "#{@app_name}-#{platform}-#{@app_env}"
      ENV["NEW_RELIC_APP_NAME"] = section[:app_name].to_s

      # Logfile
      ENV["NEW_RELIC_LOG"] = logfile.to_s if logfile
    end

  end

end
