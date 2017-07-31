module RestFtpDaemon::Transform
  class TransformError            < RestFtpDaemon::Task::TaskError; end
  class TransformMissingBinary    < TransformError; end
  class TransformMissingOutput    < TransformError; end
  class TransformMissingOptions   < TransformError; end
  class TransformFileNotFound     < TransformError; end

  class TransformBase < Task::TaskTransform
  end
end
