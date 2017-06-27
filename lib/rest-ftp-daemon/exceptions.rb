module RestFtpDaemon

  class BaseException             < StandardError; end

  class AssertionFailed           < BaseException; end

  class InvalidWorkerNumber       < BaseException; end
  class QueueCantCreateJob        < BaseException; end
  class JobTimeout                < BaseException; end
  class JobNotFound               < BaseException; end

  class JobException              < BaseException; end
  class JobAttributeMissing       < BaseException; end
  class JobUnresolvedTokens       < BaseException; end

  class LocationParseError        < BaseException; end
  class SchemeUnsupported         < BaseException; end

  class SourceUnsupported         < BaseException; end
  class SourceNotFound            < BaseException; end

  class TargetUnsupported         < BaseException; end
  class TargetFileExists          < BaseException; end
  class TargetDirectoryError      < BaseException; end
  class TargetPermissionError     < BaseException; end

  class VideoMissingBinary        < BaseException; end
  class JobUnsupportedTransform   < BaseException; end
  class TransformMissingBinary    < BaseException; end
  class TransformMissingOutput    < BaseException; end
  class TransformMissingOptions   < BaseException; end


  class VideoNotFound             < BaseException; end
  class VideoMovieError           < BaseException; end

end
