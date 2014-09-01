# Load gem files
$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
require 'rest-ftp-daemon'

# Some extra constants
APP_STARTED = Time.now
APP_LOGTO = "/tmp/#{APP_NAME}.log"

# Start REST FTP Daemon
run RestFtpDaemon::API
