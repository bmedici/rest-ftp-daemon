module Sinatra
  module RestFtpDaemon
    module Helpers

      # def check_file_presence path
      #   return File.exists? File.expand_path(path)
      # end

      def api_error http, exception
        hash = api_exception exception
        puts "api_error [#{http}] #{hash.inspect}"
        return [http, {'Content-Type' => 'application/json'}, [JSON.pretty_generate(hash)]]
      end

      def api_success http, details
        puts "api_success [#{http}] #{details.inspect}"
        return [200, {'Content-Type' => 'application/json'}, [JSON.pretty_generate(details)]]
      end

      def api_exception exception
        {
        :error => exception.class,
        :errmsg => exception.message,
        :backtrace => exception.backtrace.first,
        #:backtrace => exception.backtrace,
        }
      end

    end
  end
end
