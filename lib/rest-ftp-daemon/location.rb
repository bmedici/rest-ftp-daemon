require 'active_support/core_ext/module/delegation'
#require 'forwardable'

module RestFtpDaemon
  class Location
    # Accessors
    attr_reader :uri
    attr_reader :scheme
    attr_reader :dir
    attr_accessor :name

    # Logging
    #attr_reader :logger
    #include BmcDaemonLib::LoggerHelper

    # def_delegators :@uri,
    delegate :scheme, :host, :user, :password, :to_s, to: :uri

    def initialize path
      #@logger = BmcDaemonLib::LoggerPool.instance.get :transfer
      #log_debug "Location.initialize path[#{path}]"
      location_uri = path.dup

      # Replace tokens, fix scheme for local paths
      resolve_tokens! location_uri
      fix_scheme! location_uri

      # Parse URL
      #log_debug "Location.initialize uri[#{location_uri}]"
      parse_url location_uri

      # Ensure result does not contain tokens after replacement
      detected_tokens = detect_tokens(location_uri)
      #log_debug "Location.initialize detected_tokens: #{detected_tokens.inspect}"
      unless detected_tokens.empty?
        raise RestFtpDaemon::UnresolvedTokens, detected_tokens.join(' ')
      end

      # Check that scheme is supported
      unless @uri.scheme
        raise RestFtpDaemon::UnsupportedScheme, url
      end

      # All done
      #log_debug "Location.initialize class[#{@uri.class}] scheme[#{@uri.scheme}] dir[#{@dir}] name[#{@name}]"
    end

    def is? klass
      @uri.is_a? klass
    end

    def path
      File.join(@dir.to_s, @name.to_s)
    end

    def scan_files
      Dir.glob(path).collect do |file|
        next unless File.readable? file
        next unless File.file? file
        # Create a new location object
        self.class.new(file)
      end
    end

    def size
      return unless uri.is_a? URI::FILE
      local_fil_path = path
      return unless File.exist? local_fil_path
      return File.size local_fil_path
    end



  private

    def tokenize item
      return unless item.is_a? String
      "[#{item}]"
    end

    def resolve_tokens! path
      # Gther endpoints, and copy path string to alter it later
      endpoints = BmcDaemonLib::Conf[:endpoints]
      vectors = {}
      vectors = endpoints.clone if endpoints.is_a? Hash

      # Stack RANDOM into tokens
      vectors["RANDOM"] = SecureRandom.hex(JOB_RANDOM_LEN)

      # Replace endpoints defined in config
      vectors.each do |from, to|
        next if to.to_s.blank?
        path.gsub! tokenize(from), to
      end
    end

    def fix_scheme! path
      # path.gsub!(/^\/(.*)/, 'file:///\1')
      path.gsub! /^\/(.*)/, 'file:/\1'
    end

    def remove_multiple_slashes path
      path.gsub! /([^:])\/\//, '\1/'
    end

    def parse_url path
      # Parse that URL
      @uri = URI.parse path # rescue nil
      raise RestFtpDaemon::LocationParseError, location_path unless uri

      # Store URL parts
      # remove_multiple_slashes
      @ori_path = path
      @uri_path = uri.path
      @dir      = extract_dirname uri.path
      @name     = extract_filename uri.path

      rescue StandardError => exception
        raise RestFtpDaemon::LocationParseError, exception.message unless uri
    end

    def extract_filename path
      # match everything that's after a slash at the end of the string
      m = path.match(/\/?([^\/]+)$/)
      return m[1].to_s unless m.nil?
    end

    def extract_dirname path
      # match all the beginning of the string up to the last slash
      m = path.match(/^(.*)\/[^\/]*$/)
      return m[1].to_s unless m.nil?
    end

    def strip_leading_slash_from_dir!
      @dir.to_s.gsub!(/^\//, '')
    end

    def detect_tokens item
      item.scan /\[[^\[\]]*\]/
    end

  end
end
