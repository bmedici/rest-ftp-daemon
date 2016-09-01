module RestFtpDaemon

  class RestFtpDaemonException    < StandardError; end

  class DummyException            < RestFtpDaemonException; end

  class MissingPool               < RestFtpDaemonException; end
  class InvalidWorkerNumber       < RestFtpDaemonException; end
  class QueueCantCreateJob        < RestFtpDaemonException; end
  class JobException              < RestFtpDaemonException; end
  class JobTimeout                < RestFtpDaemonException; end
  class JobNotFound               < RestFtpDaemonException; end


  class AttributeMissing          < RestFtpDaemonException; end
  class AssertionFailed           < RestFtpDaemonException; end
  class UnresolvedTokens          < RestFtpDaemonException; end
  class LocationParseError        < RestFtpDaemonException; end
  class UnsupportedScheme         < RestFtpDaemonException; end

  class SourceNotSupported        < RestFtpDaemonException; end
  class SourceNotFound            < RestFtpDaemonException; end

  class TargetNotSupported        < RestFtpDaemonException; end
  class TargetFileExists          < RestFtpDaemonException; end
  class TargetDirectoryError      < RestFtpDaemonException; end
  class TargetPermissionError     < RestFtpDaemonException; end

end
