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
    delegate :scheme, :host, :port, :user, :password, :path, :to_s,
      to: :uri

    TEMPFILE_RANDOM_LENGTH = 8

    def initialize url
      # Debug
      @debug = Conf.at(:debug, :location)
      debug nil, nil

      # Remember origin url
      @url = url.clone
      debug :url, url

      # Detect tokens in string
      @tokens = detect_tokens(url)
      debug :tokens, @tokens.inspect
      
      # First resolve tokens
      resolve_tokens! url

      # Build URI from parameters
      build_uri url

      # Specific initializations
      case @uri
      when URI::S3    then init_aws               # Match AWS URL with BUCKET.s3.amazonaws.com
      end
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
      random = rand(36**TEMPFILE_RANDOM_LENGTH).to_s(36)
      self.name= "#{self.name}.#{random}.tmp"
    end


    def build_uri url 
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