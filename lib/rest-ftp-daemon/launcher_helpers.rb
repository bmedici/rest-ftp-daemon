module RestFtpDaemon
  class LauncherHelpers

    def self.local_port_used? port
      Timeout.timeout(BIND_PORT_TIMEOUT) do
        begin
          TCPSocket.new(BIND_PORT_LOCALHOST, port).close
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
