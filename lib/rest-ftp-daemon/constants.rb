# Configuration defaults
DEFAULT_POOL            = "default"
DEFAULT_SFTP_TIMEOUT    = 600   # 10mn
DEFAULT_PAGE_SIZE       = 50    # 50 lines
DEFAULT_RETRY_AFTER     = 10    # 10s
TARGET_BLANK             = "_blank"

# Internal job constants
JOB_RANDOM_LEN          = 8
JOB_IDENT_LEN           = 4
JOB_TEMPFILE_LEN        = 8
JOB_FTP_CHUNKMB         = 2048   # 2 MB

JOB_FFMPEG_THREADS      = 2
JOB_FFMPEG_ATTRIBUTES   = [:video_codec, :video_bitrate, :video_bitrate_tolerance, :frame_rate, :resolution, :aspect, :keyframe_interval, :x264_vprofile, :x264_preset, :audio_codec, :audio_bitrate, :audio_sample_rate, :audio_channels]

# Internal job infos
INFO_PARAMS               = :params
INFO_ERROR_MESSAGE        = :error_message
INFO_ERROR_EXCEPTION      = :error_exception
INFO_ERROR_BACKTRACE      = :error_backtrace
INFO_SOURCE_COUNT         = :source_count
INFO_SOURCE_PROCESSED     = :source_processed
INFO_SOURCE_CURRENT       = :source_current
INFO_SOURCE_FILES         = :source_files
INFO_TRANSFER_TOTAL       = :transfer_total
INFO_TRANFER_SENT         = :transfer_sent
INFO_TRANFER_PROGRESS     = :progress
INFO_TRANFER_BITRATE      = :bitrate
INFO_TARGET_FILES         = :target_files

# Constants: logger
LOGGER_FORMAT = {
  # context:  "%#{-LOG_PREFIX_WID.to_i}s %#{-LOG_PREFIX_JID.to_i}s %#{-LOG_PREFIX_ID.to_i}s ",
  # context:  "wid:%-8{wid} jid:%-12{jid} id:%-5{id}",
  context: {
    caller: "%-17s",
    wid:    "%-10s",
    jid:    "%-10s",
    id:     "%-8s",
    }
  }


# Constants: logger to be cleaned up
LOG_PIPE_LEN            = 10
LOG_INDENT              = "\t"


# Jobs statuses
JOB_STATUS_PREPARING    = "preparing"
JOB_STATUS_WORKING      = "working"

JOB_STATUS_TRANSFORMING = "transforming"

JOB_STATUS_CHECKING_SRC = "checking_source"
JOB_STATUS_CONNECTING   = "remote_connect"
JOB_STATUS_CHDIR        = "remote_chdir"
JOB_STATUS_UPLOADING    = "uploading"
JOB_STATUS_RENAMING     = "renaming"
JOB_STATUS_PREPARED     = "prepared"
JOB_STATUS_DISCONNECTING= "remote_disconnect"
JOB_STATUS_FINISHED     = "finished"

JOB_STATUS_FAILED       = "failed"
JOB_STATUS_QUEUED       = "queued"

JOB_STYLES = {
  JOB_STATUS_QUEUED      => :active,
  JOB_STATUS_FAILED      => :warning,
  JOB_STATUS_FINISHED    => :success,

  JOB_STATUS_TRANSFORMING   => :info,

  JOB_STATUS_UPLOADING   => :info,
  JOB_STATUS_RENAMING    => :info,
  }


# Jobs statuses
JOB_METHOD_FTP           = "ftp"
JOB_METHOD_FTPS          = "ftps"
JOB_METHOD_SFTP          = "sftp"
JOB_METHOD_FILE          = "file"

# Jobs types
JOB_TYPE_TRANSFER        = "transfer"
JOB_TYPE_VIDEO           = "video"
JOB_TYPE_DUMMY           = "dummy"
JOB_TYPES                = [JOB_TYPE_TRANSFER, JOB_TYPE_VIDEO, JOB_TYPE_DUMMY]

# Worker statuses
WORKER_STATUS_STARTING  = "starting"
WORKER_STATUS_WAITING   = "waiting"
WORKER_STATUS_RUNNING   = "running"
WORKER_STATUS_FINISHED  = "finished"
WORKER_STATUS_RETRYING  = "retrying"
WORKER_STATUS_TIMEOUT   = "timeout"
WORKER_STATUS_CRASHED   = "crashed"
WORKER_STATUS_CLEANING  = "cleaning"
WORKER_STATUS_REPORTING = "reporting"
WORKER_STYLES = {
  WORKER_STATUS_WAITING   => nil,
  WORKER_STATUS_RUNNING   => :info,
  WORKER_STATUS_REPORTING => :info,
  WORKER_STATUS_CLEANING  => :info,
  WORKER_STATUS_RETRYING  => :warning,
  WORKER_STATUS_CRASHED   => :danger,
  WORKER_STATUS_FINISHED  => :success,
  }


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
