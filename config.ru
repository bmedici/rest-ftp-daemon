# Load gem files
load_path_libs = File.expand_path(File.join(File.dirname(__FILE__), "lib"))
$LOAD_PATH.unshift(load_path_libs) unless $LOAD_PATH.include?(load_path_libs)
require "rest-ftp-daemon"

# Create global queue
$queue = RestFtpDaemon::JobQueue.new

# Create global stats
$stats = RestFtpDaemon::Stats.new

# Initialize workers and conchita subsystem
$pool = RestFtpDaemon::WorkerPool.new

# Rack authent
unless Settings.adminpwd.nil?
  use Rack::Auth::Basic, "Restricted Area" do |username, password|
    [username, password] == ["admin", Settings.adminpwd]
  end
end

# NewRelic profiling
GC::Profiler.enable if Settings.newrelic_enabled?

# Serve static assets
use Rack::Static, urls: ["/css", "/js", "/images"], root: "#{APP_LIBS}/static/"

# Rack reloader and mini-profiler
unless Settings.namespace == ENV_PRODUCTION
  use Rack::Reloader, 1
  # use Rack::MiniProfiler
end

# Set up encodings
Encoding.default_internal = "utf-8"
Encoding.default_external = "utf-8"

# Launch the main daemon
run RestFtpDaemon::API::Root
