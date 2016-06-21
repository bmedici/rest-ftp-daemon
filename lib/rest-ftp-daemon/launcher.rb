module RestFtpDaemon
  class Launcher
    LAUNCHER_PORT_TIMEOUT       = 3
    LAUNCHER_PORT_LOCALHOST     = "127.0.0.1"

    class << self

      def local_port_used? port
        Timeout.timeout(LAUNCHER_PORT_TIMEOUT) do
          begin
            TCPSocket.new(LAUNCHER_PORT_LOCALHOST, port).close
            true
          rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
            false
          rescue Errno::EADDRNOTAVAIL
            "local_port_used: Errno::EADDRNOTAVAIL"
          end
        end
      rescue Timeout::Error
        false
      end

    end

  end
end
