module RestFtpDaemon

  class RestFtpDaemonException < StandardError
  end

  class DummyException < RestFtpDaemonException
  end

  class RequestSourceMissing < RestFtpDaemonException
  end

end
