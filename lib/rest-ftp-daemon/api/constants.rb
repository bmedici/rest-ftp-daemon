# Jobs statuses
JOB_STYLES = {
  Job::STATUS_QUEUED              => :active,
  Job::STATUS_FAILED              => :warning,
  Job::STATUS_FINISHED            => :success,
  Job::STATUS_VIDEO_TRANSFORMING  => :info,
  Job::STATUS_EXPORT_UPLOADING    => :info,
  Job::STATUS_EXPORT_RENAMING     => :info,
  }


# Worker statuses
WORKER_STYLES = {
  Worker::STATUS_READY        => nil,
  Worker::STATUS_SLEEPING     => nil,
  Worker::STATUS_WORKING      => :info,
  
  Worker::STATUS_FINISHED     => :success,
  
  Worker::STATUS_CRASHED      => :warning,
  Worker::STATUS_TIMEOUT      => :warning,
  }