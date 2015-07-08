module RestFtpDaemon
  class Path
    attr_accessor :name
    attr_accessor :dir

    def initialize full, strip_leading_slash = false
      # Extract path parts
      @name = extract_filename full.to_s
      @dir = extract_dirname full.to_s

      # Remove leading slash if needed
      strip_leading_slash_from_dir! if strip_leading_slash
    end

    def full
      return @name if @dir.nil? || @dir.empty?
      return File.join @dir, @name
    end

    def size
      File.size full if File.exists? full
    end

  private

    def extract_filename path
      # match everything that's after a slash at the end of the string
      m = path.match /\/?([^\/]+)$/
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

  end
end
