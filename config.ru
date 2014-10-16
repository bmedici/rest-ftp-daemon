# Load gem files
APP_LIBS = File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
$LOAD_PATH.unshift(APP_LIBS) unless $LOAD_PATH.include?(APP_LIBS)
require 'rest-ftp-daemon'

# Create queue and worker pool
$queue = RestFtpDaemon::JobQueue.new
$pool = RestFtpDaemon::WorkerPool.new(Settings.workers.to_i)

# Serve static assets
use Rack::Static, :urls => ["/css", "/images"], :root => "lib/#{Settings.app_name}/static/"
run Rack::Cascade.new [RestFtpDaemon::API::Root]
