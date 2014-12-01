# Terrific constants
APP_NAME = "rest-ftp-daemon"
APP_CONF = "/etc/#{APP_NAME}.yml"
APP_VER = "0.94"

# Some global constants
IDENT_JOB_LEN = 4
IDENT_NOTIF_LEN = 4
IDENT_RANDOM_LEN = 8

# Some defaults
DEFAULT_CONNECT_TIMEOUT_SEC = 30
DEFAULT_UPDATE_EVERY_KB = 2048
DEFAULT_WORKERS = 1
DEFAULT_LOGS_PROGNAME_TRIM = 12

# Initialize markers
APP_STARTED = Time.now
APP_LIBS = File.dirname(__FILE__)

# Debugging
DEBUG_FTP_COMMANDS = false

