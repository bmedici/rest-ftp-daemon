# Load gem files
APP_LIBS = File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
$LOAD_PATH.unshift(APP_LIBS) unless $LOAD_PATH.include?(APP_LIBS)
require 'rest-ftp-daemon'

# Create queue and worker pool
$queue = RestFtpDaemon::JobQueue.new
$pool = RestFtpDaemon::WorkerPool.new(Settings.workers.to_i)

# Rack middleware
# use Rack::Etag           # Add an ETag
# use Rack::Reloader,   0
# Rack::Auth::Basic
# use Rack::Auth::Basic, "Restricted Area" do |username, password|
#   [username, password] == ['admin', 'admin']
# end
#use Rack::Deflator      # Compress

# Serve static assets
use Rack::Static, :urls => ["/css", "/images"], :root => "#{Settings.app_lib}/static/"

# Launch the main daemon
run Rack::Cascade.new [RestFtpDaemon::API::Root]
