# Terrific constants
APP_NAME = "rest-ftp-daemon"
APP_VER = "0.202"


# Logging
DEFAULT_LOGS_PIPE_LEN = 10
DEFAULT_LOGS_ID_LEN = 8
DEFAULT_LOGS_TRIM_LINE = 80


# Jobs identifiers length
JOB_RANDOM_LEN = 8
JOB_TEMPFILE_LEN = 8
JOB_IDENT_LEN = 4


# Jobs
JOB_UPDATE_KB = 2048
JOB_STATUS_UPLOADING = :uploading
JOB_STATUS_FINISHED = :finished
JOB_STATUS_QUEUED = :queued
JOB_WEIGHTS = {queued: -10, uploading: 10, finished: 50}

# Notifications
NOTIFY_PREFIX = "rftpd"
NOTIFY_USERAGENT = "#{APP_NAME} - #{APP_VER}"
NOTIFY_IDENTIFIER_LEN = 4


# Initialize defaults
APP_STARTED = Time.now
APP_LIBS = File.dirname(__FILE__)
APP_WORKERS = 1

