require 'securerandom'


module RestFtpDaemon
  class Helpers

    def self.format_bytes number, unit=""
      return "&Oslash;" if number.nil? || number.zero?

      units = ["", "k", "M", "G", "T", "P" ]
      index = ( Math.log( number ) / Math.log( 2 ) ).to_i / 10
      converted = number.to_i / ( 1024 ** index )
      "#{converted} #{units[index]}#{unit}"
    end

    def self.identifier len
      rand(36**len).to_s(36)
    end
    #SecureRandom.hex(IDENT_JOB_BYTES)

    def self.tokenize(item)
      "[#{item}]"
    end

    def self.contains_tokens(item)
      /\[[a-zA-Z0-9]+\]/.match(item)
    end

    def self.local_port_used? port
      ip = '0.0.0.0'
      timeout = 1
      begin
        Timeout::timeout(timeout) do
          begin
            TCPSocket.new(ip, port).close
            true
          rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
            false
          rescue Errno::EADDRNOTAVAIL
            "Settings.local_port_used: Errno::EADDRNOTAVAIL"
          end
        end
      rescue Timeout::Error
        false
      end
    end

    # def snakecase
    #   gsub(/::/, '/').
    #   gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    #   gsub(/([a-z\d])([A-Z])/,'\1_\2').
    #   tr('-', '_').
    #   gsub(/\s/, '_').
    #   gsub(/__+/, '_').
    #   downcase
    # end

  end
end
