require 'active_support/core_ext/module/delegation'
#require 'forwardable'

module RestFtpDaemon
  class Location

    attr_reader :original
    attr_reader :uri
    attr_reader :tokens
    attr_reader :scheme

    attr_reader :aws_region
    attr_reader :aws_bucket
    attr_reader :aws_id
    attr_reader :aws_secret

    URI_FILE_SCHEME = "file"

    # def_delegators :@uri,
    delegate :scheme, :host, :port, :user, :password, :to_s,
      to: :uri

    MY_RANDOM_LEN = 8

    def initialize param
      # Init
      @original = nil

      # Prepare endpoints
      @endpoints ||= BmcDaemonLib::Conf[:endpoints]

      # Import URI or parse URL
      if param.is_a? URI
        # Take URI as-is
        @uri = param.clone
      else
        # Build URI from parameters
        build_uri param
      end

      # Specific initializations
      case @uri
      when URI::S3    then init_aws               # Match AWS URL with BUCKET.s3.amazonaws.com
      end
    end

    # Control how the object is cloned, especially for @uri pointed by an instance variable
    def clone
      self.class.new(@uri.clone)     
    end

    def uri_is? kind
      @uri.is_a? kind
    end
  
    def local_files
      Dir.glob(path_abs).collect do |file|
        next unless File.readable? file
        next unless File.file? file

        # Create a new location object
        self.class.new(file)
      end
    end

    def size
      return unless uri.is_a? URI::FILE

      local_file_path = path_abs
      return unless File.exist? local_file_path
      return File.size local_file_path
    end

    def generate_temp_name!
      random = rand(36**MY_RANDOM_LEN).to_s(36)
      self.name= "#{self.name}.#{random}.tmp"
    end

    def name
      # match everything that's after a slash at the end of the string
      m = @uri.path.match(/\/?([^\/]+)$/)
      return m[1].to_s unless m.nil?
    end

    def name= value
      @uri.path = File.join(File.dirname(@uri.path), value)
    end

    def dir= value
      @uri.path = File.join(value, File.basename(@uri.path))
    end
    def dir
      File.dirname(@uri.path)
    end
    def dir_abs
      dir
    end
    def dir_rel
      dir.sub(/^\//, '')
    end

    def path_abs
      @uri.path
    end
    def path_rel
      @uri.path.sub(/^\//, '')
    end

  private

    def tokenize item
      return unless item.is_a? String
      "[#{item}]"
    end

    def build_uri url
      # Fix scheme if URL as none
      # url.gsub! /^\/(.*)/, 'file://\1'

      # Remember origin url
      @original = url.clone

      # Detect tokens in string, then resolve them
      @tokens = detect_tokens(url)
      resolve_tokens!(url)

      # Parse that URL
      @uri = URI.parse url # rescue nil
      raise RestFtpDaemon::LocationParseError, location_path unless @uri

      # If no scheme, assume it's a file:/// local file URL
      unless @uri.scheme
        @uri.scheme = URI_FILE_SCHEME
        @uri = URI.parse(@uri.to_s)
      end

      # Remove unnecessary double slahes
      @uri.path.gsub!(/\/+/, '/')     

      # Raise if still no scheme #FIXME
      raise RestFtpDaemon::SchemeUnsupported, url unless @uri.scheme
      # raise RestFtpDaemon::LocationParseError, base unless @uri
    end

    def resolve_tokens! path
      # Get endpoints, and copy path string to alter it later
      if @endpoints.is_a? Hash
        vectors = @endpoints.clone 
      else
        vectors = {}
      end

      # Stack RANDOM into vectors
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

    # def extract_filename path
    #   # match everything that's after a slash at the end of the string
    #   m = path.match(/\/?([^\/]+)$/)
    #   return m[1].to_s unless m.nil?
    # end

    # def extract_dirname path
    #   # match all the beginning of the string up to the last slash
    #   m = path.match(/^(.*)\/[^\/]*$/)
    #   return m[1].to_s unless m.nil?
    # end

    def detect_tokens item
      item.scan(/\[([^\[\]]*)\]/).map(&:first)
    end

    def to_debug
      return {
        to_s:     @uri.to_s,
        tokens:   @tokens.join(', '),
        scheme:   @uri.scheme,
        user:     @uri.user,
        host:     @uri.host,
        port:     @uri.port,
        dir:      dir,
        name:     name,
        aws_region: @aws_region,
        aws_id:   @aws_id,
        path_abs: path_abs,
        path_rel: path_rel,
        path_rel: path_rel,
        }
    end

  end
end