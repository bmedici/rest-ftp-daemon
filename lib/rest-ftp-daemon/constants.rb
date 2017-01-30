# Configuration defaults
DEFAULT_POOL            = "default"
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

JOB_FTP_CHUNKMB         = 2*MB
JOB_S3_MIN_PART         = 5*MB
JOB_S3_MAX_COUNT        = 10_000

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
  wid:    "%-10s",
  jid:    "%-10s",
  id:     "%-8s",
  caller: "%18s |",
  }
}


# Constants: logger to be cleaned up
LOG_PIPE_LEN            = 10
LOG_INDENT              = "\t"


# Jobs statuses
STATUS_QUEUED               = "queued"
STATUS_PREPARING            = "preparing"
STATUS_PREPARED             = "prepared"
STATUS_WORKING              = "working"
STATUS_FINISHED             = "finished"
STATUS_FAILED               = "failed"

STATUS_IMPORT_LISTING       = "import/list"

STATUS_VIDEO_TRANSFORMING   = "video/transform"

STATUS_EXPORT_CONNECTING    = "export/connect"
STATUS_EXPORT_CHDIR         = "export/chdir"
STATUS_EXPORT_UPLOADING     = "export/upload"
STATUS_EXPORT_RENAMING      = "export/rename"
STATUS_EXPORT_DISCONNECTING = "export/disconnect"


JOB_STYLES = {
  STATUS_QUEUED      => :active,
  STATUS_FAILED      => :warning,
  STATUS_FINISHED    => :success,

  STATUS_VIDEO_TRANSFORMING   => :info,

  STATUS_EXPORT_UPLOADING   => :info,
  STATUS_EXPORT_RENAMING    => :info,
  }


# Jobs statuses
JOB_METHOD_FTP           = "ftp"
JOB_METHOD_FTPS          = "ftps"
JOB_METHOD_SFTP          = "sftp"
JOB_METHOD_FILE          = "file"

# Jobs types
JOB_TYPE_TRANSFER        = "transfer"
JOB_TYPE_VIDEO           = "video"
JOB_TYPE_WORKFLOW        = "workflow"
JOB_TYPE_DUMMY           = "dummy"
JOB_TYPES                = [JOB_TYPE_TRANSFER, JOB_TYPE_VIDEO, JOB_TYPE_WORKFLOW, JOB_TYPE_DUMMY]

# Worker statuses
WORKER_STATUS_STARTING  = "starting"
WORKER_STATUS_WAITING   = "waiting"
WORKER_STATUS_RUNNING   = "running"
WORKER_STATUS_FINISHED  = "finished"
WORKER_STATUS_TIMEOUT   = "timeout"
WORKER_STATUS_CRASHED   = "crashed"
WORKER_STYLES = {
  WORKER_STATUS_WAITING   => nil,
  WORKER_STATUS_RUNNING   => :info,
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

