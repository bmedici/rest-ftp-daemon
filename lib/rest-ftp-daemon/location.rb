require 'active_support/core_ext/module/delegation'
#require 'forwardable'

module RestFtpDaemon
  class Location
    include CommonHelpers

    # Accessors
    attr_accessor :name

    attr_reader :url
    attr_reader :uri
    attr_reader :tokens
    attr_reader :scheme
    attr_reader :dir

    attr_reader :aws_region
    attr_reader :aws_bucket
    attr_reader :aws_id
    attr_reader :aws_secret

    # def_delegators :@uri,
    delegate :scheme, :host, :port, :user, :password, :to_s,
      to: :uri

    def initialize url
      # Check parameters
      # unless url.is_a? String
      #   raise RestFtpDaemon::AssertionFailed, "location/init/string: #{url.inspect}"
      # end   
      debug nil

      @url = url.clone
      debug :url, url
      @tokens = []

      # Detect tokens in string
      @tokens = detect_tokens(url)
      debug :tokens, @tokens.inspect

      # First resolve tokens
      resolve_tokens! url

      # Build URI from parameters
      build_uri url

      # Extract dir and name
      build_dir_name

      # Specific initializations
      case @uri
      when URI::S3    then init_aws               # Match AWS URL with BUCKET.s3.amazonaws.com
      end
    end

    def uri_is? kind
      @uri.is_a? kind
    end

    def path
      File.join(@dir.to_s, name.to_s)
    end
    
    def path_fs
      '/' + path
    end
    def dir_fs
      '/' + @dir
    end

    def local_files
      Dir.glob("/#{path}").collect do |file|
        next unless File.readable? file
        next unless File.file? file
        # Create a new location object
        self.class.new(file)
      end
    end

    def size
      return unless uri.is_a? URI::FILE

      local_file_path = path_fs
      return unless File.exist? path_fs
      return File.size path_fs
    end

    def generate_temp_name!
      @name = "#{@name}.temp-#{identifier(JOB_TEMPFILE_LEN)}"
    end

    # def scheme? condition
    #   return @uri.scheme == condition
    # end

  private

    def tokenize item
      return unless item.is_a? String
      "[#{item}]"
    end

    def build_uri url
      # Fix scheme if URL as none
      url.gsub! /^\/(.*)/, 'file:/\1'

      # Parse that URL
      @uri = URI.parse url # rescue nil
      raise RestFtpDaemon::LocationParseError, location_path unless @uri

      # Remove unnecessary double slahes
      @uri.path.gsub!(/\/+/, '/')

      # Check we finally have a scheme
      debug :scheme, @uri.scheme 
      debug :path, @uri.path
      debug :host, @uri.host
      debug :to_s, @uri.to_s

      # Raise if still no scheme #FIXME
      raise RestFtpDaemon::SchemeUnsupported, url unless @uri.scheme
      # raise RestFtpDaemon::LocationParseError, base unless @uri
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
        next unless to.is_a? String
        next if to.to_s.empty?
        path.gsub! tokenize(from), to
      end

      # Ensure result does not contain tokens after replacement
      detected = detect_tokens(path)
      unless detected.empty?
        raise RestFtpDaemon::JobUnresolvedTokens, 'unresolved tokens: ' + detected.join(' ')
      end
    end

    def build_dir_name
      # Store URL parts (remove leading slashes in dir)
      @dir      = extract_dirname(@uri.path).gsub(/^\//, '')
      @name     = extract_filename(@uri.path)

      debug :dir, dir
      debug :name, name
    end

    def init_aws
      # Split hostname
      parts       = @uri.host.split('.')

      # Pop parts
      aws_tld     = parts.pop
      aws_domain  = parts.pop
      @aws_region = parts.pop
      aws_tag     = parts.pop
      @aws_bucket = parts.pop

      # Credentials from config
      @aws_id     = Conf.at(:credentials, @uri.host, :id)
      @aws_secret = Conf.at(:credentials, @uri.host, :secret)
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

    def detect_tokens item
      # item.scan /\[([^\[\]]*)\]/
      item.scan(/\[([^\[\]]*)\]/).map(&:first)
    end

    def debug var, val = nil
      # Read conf if not already cached
      @debug ||= Conf.at(:debug, :location)

      # Skip if no debug requeste
      return unless @debug

      # Dump line
      if var.nil?
        printf("|%s \n", "-"*100) 
      else
        printf("| %-15s: %s \n", var, val)
      end
    end

  end
end