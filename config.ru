# Load gem files
$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
require 'rest-ftp-daemon'

# Some extra constants
APP_STARTED = Time.now

# Start REST FTP Daemon
#run Rack::Cascade.new [Rack::File.new("/public"), RestFtpDaemon::API::Root]
run Rack::Cascade.new [RestFtpDaemon::API::Root]
