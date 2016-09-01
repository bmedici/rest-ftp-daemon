require 'active_support/core_ext/module/delegation'
#require 'forwardable'

module RestFtpDaemon
  class Location
    # Accessors
    attr_accessor :name

    attr_reader :uri
    attr_reader :scheme
    attr_reader :dir


    attr_reader :aws_region
    attr_reader :aws_bucket
    attr_reader :aws_id
    attr_reader :aws_secret

    # Logging
    #attr_reader :logger
    #include BmcDaemonLib::LoggerHelper

    # def_delegators :@uri,
    delegate :scheme, :host, :port, :user, :password, :to_s,
      to: :uri

    def initialize path
      # Strip spaces before/after, copying original "path" at the same time
      location_uri = path.strip

      # Replace tokens, fix scheme for local paths
      resolve_tokens! location_uri
      fix_scheme! location_uri

      # Parse URL
      parse_url location_uri

      # Match AWS URL with BUCKET.s3.amazonaws.com
      init_aws if @uri.is_a? URI::S3

      # Set default user if not provided

      # Ensure result does not contain tokens after replacement
      detected_tokens = detect_tokens(location_uri)
      unless detected_tokens.empty?
        raise RestFtpDaemon::UnresolvedTokens, detected_tokens.join(' ')
      end
      # init_username

      # Check that scheme is supported
      unless @uri.scheme
        raise RestFtpDaemon::UnsupportedScheme, url
      end
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
        next if to.to_s.empty?
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
      raise RestFtpDaemon::LocationParseError, location_path unless @uri

      # Store URL parts
      @ori_path = path
      @uri_path = uri.path
      @dir      = extract_dirname uri.path
      @name     = extract_filename uri.path
    end

    # def init_username
    #   @uri.user ||= "anonymous"
    # end

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

    def strip_leading_slash_from_dir!
      @dir.to_s.gsub!(/^\//, '')
    end

    def detect_tokens item
      item.scan /\[[^\[\]]*\]/
    end

  end
end
