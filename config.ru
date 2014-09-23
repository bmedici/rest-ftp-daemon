# Load gem files
$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
require 'rest-ftp-daemon'

# Some extra constants
APP_STARTED = Time.now

# Create worker pool
$queue = RestFtpDaemon::JobQueue.new
$pool = RestFtpDaemon::WorkerPool.new(Settings.workers.to_i)

# Start REST FTP Daemon
use Rack::Static, :urls => ["/css", "/images"], :root => "#{APP_ROOT}/lib/rest-ftp-daemon/static/"
run Rack::Cascade.new [RestFtpDaemon::API::Root]
