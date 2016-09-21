require 'active_support/core_ext/module/delegation'
#require 'forwardable'

module RestFtpDaemon
  class Location
    include CommonHelpers

    # Accessors
    attr_accessor :name

    attr_reader :original
    attr_reader :uri
    attr_reader :scheme
    attr_reader :dir

    attr_reader :aws_region
    attr_reader :aws_bucket
    attr_reader :aws_id
    attr_reader :aws_secret

    # Logging
    #include BmcDaemonLib::LoggerHelper

    # def_delegators :@uri,
    delegate :scheme, :host, :port, :user, :password, :to_s,
      to: :uri

    def initialize original
      unless original.is_a? String
        raise RestFtpDaemon::AssertionFailed, "location/original/string: #{original.inspect}"
      end

      # Strip spaces before/after, copying original "path" at the same time
      @original = original
      location_uri = original.strip

      # Replace tokens, fix scheme for local paths
      resolve_tokens! location_uri
      fix_scheme! location_uri

      # Ensure result does not contain tokens after replacement
      detected_tokens = detect_tokens(location_uri)
      unless detected_tokens.empty?
        raise RestFtpDaemon::JobUnresolvedTokens, 'unresolved tokens: ' + detected_tokens.join(' ')
      end

      # Parse URL and do specific initializations
      parse_url location_uri
      case @uri
      when URI::FILE  then init_file
      when URI::S3    then init_aws               # Match AWS URL with BUCKET.s3.amazonaws.com
      end

      # Check that scheme is supported
      unless @uri.scheme
        raise RestFtpDaemon::SchemeUnsupported, url
        # raise RestFtpDaemon::SchemeUnsupported, @uri
      end
    end

    def is? kind
      @uri.is_a? kind
    end

    def path
      return @name if @dir.nil?
      File.join(@dir.to_s, @name.to_s)
    end
    alias :to_s :path

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

    def generate_temp_name!
      @name = "#{@name}.temp-#{identifier(JOB_TEMPFILE_LEN)}"
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
        next unless to.is_a? String
        next if to.to_s.empty?
        path.gsub! tokenize(from), to
      end
    end

    def fix_scheme! path
      # path.gsub!(/^\/(.*)/, 'file:///\1')
      path.gsub! /^\/(.*)/, 'file:/\1'
    end

    def parse_url path
      # Parse that URL
      @uri = URI.parse path # rescue nil
      raise RestFtpDaemon::LocationParseError, location_path unless @uri

      # Path cleanup
      cleaned  = @uri.path.clone

      # remove_leading_slashes
      cleaned.gsub! /^\//, ''

      # remove_multiple_slashes
      cleaned.gsub! /([^:])\/\//, '\1/'

      # Store URL parts
      @dir      = extract_dirname  cleaned
      @name     = extract_filename cleaned
    end

    # def init_username
    #   @uri.user ||= "anonymous"
    # end

    def init_file
      # Dir is absolute
      @dir = File.join('/', @dir.to_s)
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

      # Clear @dir
      @dir = nil
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
      item.scan /\[[^\[\]]*\]/
    end

  end
end
