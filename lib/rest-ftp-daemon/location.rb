require 'active_support/core_ext/module/delegation'
#require 'forwardable'

module RestFtpDaemon
  class Location

    attr_reader :url
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

    def initialize original, endpoints = nil
      # Debug
      @debug = Conf.at(:debug, :location)
      debug nil, nil

      # Fallback endpoints
      endpoints ||= BmcDaemonLib::Conf[:endpoints]

      # Remember origin url
      @url = original.clone
      debug :url, original

      # Detect tokens in string
      @tokens = detect_tokens(original)
      debug :tokens, @tokens.inspect
      
      # First resolve tokens
      resolve_tokens!(original, endpoints)

      # Build URI from parameters
      build_uri original

      # Specific initializations
      case @uri
      when URI::S3    then init_aws               # Match AWS URL with BUCKET.s3.amazonaws.com
      end
    end

    # Control how the object is cloned, especially for @uri pointed by an instance variable
    def initialize_clone(other)
      debug "cloning", "other.object_id"
      super
      #initialize_copy(other)
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
      puts "size(#{local_file_path})"
      return unless File.exist? local_file_path
      return File.size local_file_path
    end

    def generate_temp_name!
      random = rand(36**MY_RANDOM_LEN).to_s(36)
      self.name= "#{self.name}.#{random}.tmp"
    end

    def name
      File.basename(@uri.path)
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
      # url.gsub! /^\/(.*)/, 'file:///\1'

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

      # Check we finally have a scheme
      debug :uri_to_s,  @uri.to_s
      debug :scheme,    @uri.scheme 
      debug :host,      @uri.host
      debug :path,      @uri.path
      debug :path_abs,  path_abs
      debug :path_rel,  path_rel
      debug :dir,       dir
      debug :name,      name

      # Raise if still no scheme #FIXME
      raise RestFtpDaemon::SchemeUnsupported, url unless @uri.scheme
      # raise RestFtpDaemon::LocationParseError, base unless @uri
    end

    def resolve_tokens! path, endpoints = {}
      # Get endpoints, and copy path string to alter it later
      if endpoints.is_a? Hash
        vectors = endpoints.clone 
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

    def debug var, val = nil
      # Skip if no debug requested
      return unless @debug

      # debug line
      if var.nil?
        printf("|%s \n", "-"*100) 
      else
        printf("| %-15s: %s \n", var, val)
      end
    end

  end
end