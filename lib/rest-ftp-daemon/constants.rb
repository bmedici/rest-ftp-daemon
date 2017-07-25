# Configuration defaults
DEFAULT_SFTP_TIMEOUT    = 600   # 10mn
DEFAULT_PAGE_SIZE       = 50    # 50 lines
DEFAULT_RETRY_AFTER     = 10    # 10s
TARGET_BLANK            = "_blank"
KB                      = 1024
MB                      = 1024*KB
GB                      = 1024*MB


# Internal job constants
JOB_RANDOM_LEN          = 8
JOB_IDENT_LEN           = 4
JOB_TEMPFILE_LEN        = 8
JOB_DELAY_TASKS         = 0


# Internal job infos
INFO_PARAMS               = :params
INFO_ERROR_MESSAGE        = :error_message
INFO_ERROR_EXCEPTION      = :error_exception
INFO_ERROR_BACKTRACE      = :error_backtrace
INFO_CURRENT              = :current
INFO_SOURCE_FILES         = :source_files
INFO_TRANSFER_TOTAL       = :transfer_total
INFO_TRANFER_SENT         = :transfer_sent
INFO_TRANFER_PROGRESS     = :progress
INFO_TRANFER_BITRATE      = :bitrate
INFO_TARGET_FILES         = :target_files


# Constants: logger to be cleaned up
LOG_PIPE_LEN            = 10
LOG_INDENT              = "\t"



# Jobs statuses
JOB_METHOD_FTP           = "ftp"
JOB_METHOD_FTPS          = "ftps"
JOB_METHOD_SFTP          = "sftp"
JOB_METHOD_FILE          = "file"


# Plugin types
PLUGIN_TRANSFORM         = "transform"
PLUGIN_REMOTE            = "remote"


# API mountpoints
MOUNT_SWAGGER_JSON        = "/swagger.json"
MOUNT_SWAGGER_UI          = "/swagger.html"
MOUNT_JOBS               = "/jobs"
MOUNT_BOARD              = "/board"
MOUNT_STATUS             = "/status"
MOUNT_DEBUG              = "/debug"
MOUNT_CONFIG             = "/config"


# Notifications
NOTIFY_PREFIX           = "rftpd"
NOTIFY_IDENTIFIER_LEN   = 4
NOTIFY_TIMEOUT			= 30


# Constants: logger
LOGGER_FORMAT = {
# context:  "%#{-LOG_PREFIX_WID.to_i}s %#{-LOG_PREFIX_JID.to_i}s %#{-LOG_PREFIX_ID.to_i}s ",
# context:  "wid:%-8{wid} jid:%-12{jid} id:%-5{id}",
context: {
  wid:    "%-8s ",
  jid:    "%-8s ",
  id:     "%-#{NOTIFY_IDENTIFIER_LEN}s ",
  caller: "%-22s | ",
  }
}



