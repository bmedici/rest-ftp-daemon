# FIXME: files named with hyphens will not be found by Chamber for now
require "chamber"
CONF_PIDFILE_BASE_DIR = "/tmp/"


module Shared
  class ConfigMissingParameter    < StandardError; end
  class ConfigOtherError          < StandardError; end
  class ConfigParseError          < StandardError; end
  class ConfigMultipleGemspec     < StandardError; end
  class ConfigMissingGemspec      < StandardError; end

  class Conf
    extend Chamber

    class << self
      attr_accessor :app_env
      attr_reader   :app_root
      attr_reader   :app_libs
      attr_reader   :app_name
      attr_reader   :app_ver
      attr_reader   :app_started
      attr_reader   :app_spec
      attr_reader   :files
      attr_reader   :host

    end

    def self.init app_root
      # Permanent flags
      @initialized  = true
      @app_started  = Time.now

      # Default values
      @files        ||= []
      @app_name     ||= "app_name"
      @app_env      ||= "production"
      @host         ||= `hostname`.to_s.chomp.split(".").first

      # Store and clean app_root
      @app_root = File.expand_path(app_root)

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
      #add_default_config
      add_config generate(:config_defaults)
      add_config generate(:config_etc)

      # Return something
      return @app_name
    end

    def self.prepare args = {}
      ensure_init

      # Add extra config file
      add_config args[:config]

      # Load configuration files
      reload!

      # Set Rack env
      ENV["RACK_ENV"] = @app_env.to_s

      # Init New Relic
      prepare_newrelic self[:newrelic], self.at(:logs, :newrelic)

      # Try to access any key to force parsing of the files
      self[:dummy]

    rescue Psych::SyntaxError => e
      fail ConfigParseError, e.message
    rescue StandardError => e
      fail ConfigOtherError, "#{e.message} \n #{e.backtrace.to_yaml}"
    end

    # Reload files
    def self.reload!
      ensure_init
      load_files
    end

    def self.dump
      ensure_init
      to_hash.to_yaml(indent: 4, useheader: true, useversion: false )
    end

    # Direct access to any depth
    def self.at *path
      ensure_init
      path.reduce(Conf) { |m, key| m && m[key.to_s] }
    end

    def self.newrelic_enabled?
      ensure_init
      self[:newrelic] && self[:newrelic][:licence]
    end

    # Defaults generators
    def self.generate what
      ensure_init
      return case what

      when :user_agent
        "#{@app_name}/#{@app_ver}" if @app_name && @app_ver

      when :config_defaults
        "#{@app_root}/defaults.yml" if @app_root

      when :config_etc
        "/etc/#{@app_name}.yml" if @app_name

      when :process_name
        parts = [@app_name, @app_env]
        parts << self[:port] if self[:port]
        parts.join('-')

      when :pidfile
        File.expand_path sprintf(
          "%s/%s.pid",
          CONF_PIDFILE_BASE_DIR,
          self.generate(:process_name)
          )

      when :config_message
        config_etc = self.generate(:config_etc)
        config_sample = "#{@app_root}/#{@app_name}.sample.yml"

        "A default configuration is available here: #{config_sample}.
        You should copy it to the default location: #{config_etc}.
        sudo cp #{config_sample} #{config_etc}"

      end

    end


  protected

    def self.load_files
      puts "load_files"
      load files: @files, namespaces: { environment: @app_env }
    end


    def self.add_config path
      puts "add_config: #{path}"
      @files << File.expand_path(path) if path && File.readable?(path)
    end

    def self.prepare_newrelic section, logfile
      # Disable NewRelic if no config present
      unless self.newrelic_enabled?
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

      # Build NewRelic app_name if not provided as-is
      if section[:app_name]
        ENV["NEW_RELIC_APP_NAME"] = section[:app_name].to_s
      else
        stack = []
        stack << (section[:prefix] || @app_name)
        stack << section[:platform] if section[:platform]
        stack << @app_env
        text = stack.join('-')
        ENV["NEW_RELIC_APP_NAME"] = "#{text}-#{host};#{text}"
      end

      # Logfile
      ENV["NEW_RELIC_LOG"] = logfile.to_s if logfile
    end

  private

    def self.ensure_init
      # Skip is already done
      return if @initialized

      # Go through init if not already done
      self.init
    end

  end
end
