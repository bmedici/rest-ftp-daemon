# Terrific constants
APP_NAME = "rest-ftp-daemon"
APP_NICK = "rftpd"
APP_VER = "0.211.0"


# Jobs and workers
JOB_RANDOM_LEN          = 8
JOB_IDENT_LEN           = 4
JOB_TEMPFILE_LEN        = 8
JOB_STATUS_UPLOADING    = :uploading
JOB_STATUS_RENAMING     = :renaming
JOB_STATUS_FINISHED     = :finished
JOB_STATUS_FAILED       = :failed
JOB_STATUS_QUEUED       = :queued


# Logging and startup
LOG_PIPE_LEN            = 10
LOG_COL_WID             = 4
LOG_COL_JID             = JOB_IDENT_LEN+3+2
LOG_COL_ID              = 6
LOG_TRIM_LINE           = 80


# Notifications
NOTIFY_PREFIX           = "rftpd"
NOTIFY_USERAGENT        = "#{APP_NAME} - #{APP_VER}"
NOTIFY_IDENTIFIER_LEN   = 4


# Dashboard row styles
JOB_STYLES = {
  JOB_STATUS_QUEUED     => :active,
  JOB_STATUS_FAILED     => :warning,
  JOB_STATUS_FINISHED   => :success,
  JOB_STATUS_UPLOADING  => :info,
  JOB_STATUS_RENAMING   => :info,
  }
WORKER_STYLES = {
  :waiting              => :success,
  :processing           => :info,
  :crashed              => :danger,
  :done                 => :success,
  :dead                 => :danger
  }


# Configuration defaults
DEFAULT_WORKER_TIMEOUT  = 3600
DEFAULT_FTP_CHUNK       = 2048


# Initialize defaults
APP_STARTED = Time.now
APP_LIBS = File.dirname(__FILE__)
APP_WORKERS = 1

