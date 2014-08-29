# Load gem files
$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
require 'rest-ftp-daemon'

# Start REST FTP Daemon
run RestFtpDaemon::API
