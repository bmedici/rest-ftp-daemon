# Load gem files
# load_path_libs = File.expand_path(File.join(File.dirname(__FILE__), "lib"))
load_path_libs = File.expand_path "lib", File.dirname(__FILE__)
$LOAD_PATH.unshift(load_path_libs) unless $LOAD_PATH.include?(load_path_libs)
require "rest-ftp-daemon"

# Create global queue
$queue = RestFtpDaemon::JobQueue.new

# Initialize workers
$pool = RestFtpDaemon::WorkerPool.new
$pool.start!

# Rack authent
unless Conf[:adminpwd].nil?
  use Rack::Auth::Basic, "Restricted Area" do |username, password|
    [username, password] == ["admin", Conf[:adminpwd]]
  end
end

# Serve static assets
use Rack::Static, urls: ["/css", "/js", "/images"], root: "#{Conf.app_libs}/static/"

# Rack reloader and mini-profiler
unless Conf.app_env == "production"
  # use Rack::Reloader, 1
  # use Rack::MiniProfiler
end

# Launch the main daemon
run RestFtpDaemon::API::Root
