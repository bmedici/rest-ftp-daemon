# Terrific constants
APP_NAME = "rest-ftp-daemon"
APP_NICK = "rftpd"
APP_VER = "0.241"

# Provide default config file information
APP_LIB = File.expand_path File.dirname(__FILE__)
APP_ROOT = File.expand_path(File.dirname(__FILE__) + "/../../")

DEFAULT_CONFIG_PATH = File.expand_path "/etc/#{APP_NAME}.yml"
SAMPLE_CONFIG_FILE = File.expand_path(File.join File.dirname(__FILE__), "/../../rest-ftp-daemon.yml.sample")

#SAMPLE_CONFIG_FILE = File.expand_path("#{app_root}/#{APP_NAME}.yml.sample")
TAIL_MESSAGE = <<EOD

A default configuration is available here: #{SAMPLE_CONFIG_FILE}.
You should copy it to the expected location #{DEFAULT_CONFIG_PATH}:

sudo cp #{SAMPLE_CONFIG_FILE} #{DEFAULT_CONFIG_PATH}
EOD

# Jobs and workers
JOB_RANDOM_LEN          = 8
JOB_IDENT_LEN           = 4
JOB_TEMPFILE_LEN        = 8
JOB_UPDATE_INTERVAL     = 1

JOB_STATUS_UPLOADING    = :uploading
JOB_STATUS_RENAMING     = :renaming
JOB_STATUS_PREPARED     = :prepared
JOB_STATUS_FINISHED     = :finished
JOB_STATUS_FAILED       = :failed
JOB_STATUS_QUEUED       = :queued

WORKER_STATUS_STARTING  = :starting
WORKER_STATUS_WAITING   = :waiting
WORKER_STATUS_RUNNING   = :running
WORKER_STATUS_FINISHED  = :finished
WORKER_STATUS_TIMEOUT   = :timeout
WORKER_STATUS_CRASHED   = :crashed
WORKER_STATUS_CLEANING  = :cleaning


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
LOG_INDENT              = "\t"

BIND_PORT_TIMEOUT       = 3
BIND_PORT_LOCALHOST     = '127.0.0.1'



# Notifications
NOTIFY_PREFIX           = "rftpd"
NOTIFY_USERAGENT        = "#{APP_NAME}/v#{APP_VER}"
NOTIFY_IDENTIFIER_LEN   = 4


# Dashboard row styles
DASHBOARD_JOB_STYLES = {
  JOB_STATUS_QUEUED     => :active,
  JOB_STATUS_FAILED     => :warning,
  JOB_STATUS_FINISHED   => :success,
  JOB_STATUS_UPLOADING  => :info,
  JOB_STATUS_RENAMING   => :info,
  }
DASHBOARD_WORKER_STYLES = {
  waiting:              :success,
  working:              :info,
  crashed:              :danger,
  done:                 :success,
  dead:                 :danger
  }


# API server
# API_LISTEN_HOST = "0.0.0.0"


# Configuration defaults
DEFAULT_WORKER_TIMEOUT  = 3600
DEFAULT_FTP_CHUNK       = 1024
DEFAULT_PAGE_SIZE       = 40
DEFAULT_WORKERS         = 1
DEFAULT_RETRY_DELAY     = 10

DEFAULT_SFTP_TIMEOUT    = 30


# Initialize defaults
APP_STARTED = Time.now
APP_LIBS = File.dirname(__FILE__)

