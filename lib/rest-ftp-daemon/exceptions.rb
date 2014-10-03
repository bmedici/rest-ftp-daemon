module RestFtpDaemon

  class RestFtpDaemonException < StandardError; end

  class DummyException < RestFtpDaemonException; end

  class RequestSourceMissing     < RestFtpDaemonException; end
  class RequestSourceNotFound    < RestFtpDaemonException; end
  class RequestTargetMissing     < RestFtpDaemonException; end
  class RequestTargetScheme      < RestFtpDaemonException; end

  class JobPrerequisitesNotMet   < RestFtpDaemonException; end

  class JobNotFound              < RestFtpDaemonException; end
  class JobSourceMissing         < RestFtpDaemonException; end
  class JobSourceNotFound        < RestFtpDaemonException; end
  class JobTargetMissing         < RestFtpDaemonException; end
  class JobTargetUnsupported     < RestFtpDaemonException; end
  class JobTargetUnparseable     < RestFtpDaemonException; end
  #class JobTargetPermission      < RestFtpDaemonException; end
  class JobTargetFileExists      < RestFtpDaemonException; end
  class JobPrerequisitesNotMet      < RestFtpDaemonException; end


  class NotificationMissingUrl   < RestFtpDaemonException; end
  class NotificationMissingSignal   < RestFtpDaemonException; end


end
