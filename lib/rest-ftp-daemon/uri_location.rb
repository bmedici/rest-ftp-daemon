require 'uri'
require "securerandom"

Location = URI


module Location

  MY_FILE_SCHEME = "file"
  MY_RANDOM_LEN = 10

  class FILE < Generic
  end

  class S3 < Generic
  end

  class FTPS < Generic
    DEFAULT_PORT = 21
  end

  class FTPES < Generic
    DEFAULT_PORT = 21
  end

  class SFTP < Generic
    DEFAULT_PORT = 22
  end


  # Extra schemes
  @@schemes["FTPS"]   = FTPS
  @@schemes["FTPES"]  = FTPES
  @@schemes["SFTP"]   = SFTP
  @@schemes["S3"]     = S3
  @@schemes["FILE"]   = FILE


  # Parser with tokens
  def self.from original, endpoints = nil
    # Resolve tokens
    resolved = resolve_tokens(original, endpoints) unless endpoints.nil?

    # Parse that URL
    result = self.parse("#{string}.tmp")
    # raise RestFtpDaemon::LocationParseError, location_path unless result

    # If no scheme, assume it's a file:/// local file URL
    unless @scheme
      @scheme = MY_FILE_SCHEME
      result = self.parse(result.to_s)
    end

    # Remember the original string
    result.url = original

    # Remove unnecessary double slahes
    result.path.gsub!(/\/+/, '/')

    # Return this instance
    return result
  end


  # Add methods on Location::Generic
  class Generic
    attr_accessor :url

    def detect_tokens item
      item.scan(/\[([^\[\]]*)\]/).map(&:first)
    end

    def resolve_tokens! endpoints
      # Gther endpoints, and copy path string to alter it later
      
      vectors = {}
      vectors = endpoints.clone if endpoints.is_a? Hash

      # Stack RANDOM into tokens
      vectors["RANDOM"] = SecureRandom.hex(MY_RANDOM_LEN)

      # Replace endpoints defined in config
      vectors.each do |from, to|
        next unless to.is_a? String
        next if to.to_s.empty?
        @path.gsub! tokenize(from), to
      end

      # Ensure result does not contain tokens after replacement
      detected = detect_tokens(@path)
      unless detected.empty?
        raise RestFtpDaemon::JobUnresolvedTokens, 'unresolved tokens: ' + detected.join(' ')
      end
    end

    # Extra methods
    def name
      File.basename(@path)
    end
    def name= value
      @path = File.join(File.dirname(@path), value)
    end

    def dir= value
      @path = File.join(value, File.basename(@path))
    end
    def dir
      File.dirname(@path)
    end
    def dir_abs
      dir
    end
    def dir_rel
      dir.sub(/^\//, '')
    end

    def path_abs
      @path
    end
    def path_rel
      @path.sub(/^\//, '')
    end

  private

    def tokenize item
      return unless item.is_a? String
      "[#{item}]"
    end    

  end
end

