#require_relative "../job"

# Jobs statuses
JOB_STYLES = {
  RestFtpDaemon::Job::STATUS_QUEUED              => :active,
  RestFtpDaemon::Job::STATUS_FAILED              => :warning,
  RestFtpDaemon::Job::STATUS_FINISHED            => :success,
  RestFtpDaemon::Job::STATUS_TASK_PROCESSING  => :info,
  RestFtpDaemon::Job::STATUS_EXPORT_UPLOADING    => :info,
  RestFtpDaemon::Job::STATUS_EXPORT_RENAMING     => :info,
  }


# Worker statuses
WORKER_STYLES = {
  RestFtpDaemon::Worker::STATUS_READY        => nil,
  RestFtpDaemon::Worker::STATUS_SLEEPING     => nil,
  RestFtpDaemon::Worker::STATUS_WORKING      => :info,
  
  RestFtpDaemon::Worker::STATUS_FINISHED     => :success,
  
  RestFtpDaemon::Worker::STATUS_CRASHED      => :warning,
  RestFtpDaemon::Worker::STATUS_TIMEOUT      => :warning,
  }