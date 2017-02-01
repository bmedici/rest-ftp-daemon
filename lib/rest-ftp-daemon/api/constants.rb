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
  WorkerBase::STATUS_READY        => nil,
  WorkerBase::STATUS_SLEEPING     => nil,
  WorkerBase::STATUS_WORKING      => :info,
  
  WorkerBase::STATUS_FINISHED     => :success,
  
  WorkerBase::STATUS_CRASHED      => :warning,
  WorkerBase::STATUS_TIMEOUT      => :warning,
  }