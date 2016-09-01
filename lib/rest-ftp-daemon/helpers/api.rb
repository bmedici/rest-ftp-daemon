module RestFtpDaemon
  module ApiHelpers

    def log_request
      if env.nil?
        puts "HTTP_ENV_IS_NIL: #{env.inspect}"
        return
      end

      request_method = env['REQUEST_METHOD']
      request_path   = env['REQUEST_PATH']
      request_uri    = env['REQUEST_URI']
      log_info       "HTTP #{request_method} #{request_uri}", params
    end

    def get_censored_config
      config              = Conf.to_hash
      config[:users]      = Conf[:users].keys if Conf[:users]
      config[:endpoints]  = Conf[:endpoints].keys if Conf[:endpoints]
      config
    end

  end
end
