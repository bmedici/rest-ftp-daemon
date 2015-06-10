# Terrific constants
APP_NAME = "rest-ftp-daemon"
APP_NICK = "rftpd"
APP_VER = "0.222.0"


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
LOG_COL_WID             = 8
LOG_COL_JID             = JOB_IDENT_LEN+3+2
LOG_COL_ID              = 6
LOG_TRIM_LINE           = 80
LOG_DUMPS               = File.dirname(__FILE__) + "/../../log/"
LOG_ROTATION            = "daily"
LOG_FORMAT_TIME         = "%Y-%m-%d %H:%M:%S"
LOG_FORMAT_PREFIX       = "%s %s\t%-#{LOG_PIPE_LEN.to_i}s\t"
LOG_FORMAT_MESSAGE      = "%#{-LOG_COL_WID.to_i}s\t%#{-LOG_COL_JID.to_i}s\t%#{-LOG_COL_ID.to_i}s"
LOG_NEWLINE             = "\n"

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
  waiting:              :success,
  working:              :info,
  crashed:              :danger,
  done:                 :success,
  dead:                 :danger
  }
PAGINATE_MAX            = 30


# Configuration defaults
DEFAULT_WORKER_TIMEOUT  = 3600
DEFAULT_FTP_CHUNK       = 2048


# Initialize defaults
APP_STARTED = Time.now
APP_LIBS = File.dirname(__FILE__)
APP_WORKERS = 1

