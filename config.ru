# Load gem files
APP_LIBS = File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
$LOAD_PATH.unshift(APP_LIBS) unless $LOAD_PATH.include?(APP_LIBS)
require 'rest-ftp-daemon'

# Create queue and worker pool
$queue = RestFtpDaemon::JobQueue.new
$pool = RestFtpDaemon::WorkerPool.new(Settings[:workers] || DEFAULT_WORKERS)

# Rack middleware
# use Rack::Etag           # Add an ETag
# use Rack::Reloader,   0
unless Settings.adminpwd.nil?
  use Rack::Auth::Basic, "Restricted Area" do |username, password|
    [username, password] == ['admin', Settings.adminpwd]
  end
end

# Serve static assets
use Rack::Static, :urls => ["/css", "/images"], :root => "#{APP_LIBS}/static/"

# Launch the main daemon
run Rack::Cascade.new [RestFtpDaemon::API::Root]
