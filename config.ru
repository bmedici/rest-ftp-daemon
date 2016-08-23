# Load gem files
# load_path_libs = File.expand_path(File.join(File.dirname(__FILE__), "lib"))
load_path_libs = File.expand_path "lib", File.dirname(__FILE__)
$LOAD_PATH.unshift(load_path_libs) unless $LOAD_PATH.include?(load_path_libs)
require "rest-ftp-daemon"

# Rack authent
unless Conf[:adminpwd].nil?
  use Rack::Auth::Basic, "Restricted Area" do |username, password|
    [username, password] == ["admin", Conf[:adminpwd]]
  end
end

# Serve static assets
use Rack::Static, root: "#{Conf.app_libs}/static/", urls: [
  "/css",
  "/js",
  "/images",
  "/swagger/",
  MOUNT_SWAGGER,
  ]

# Rack reloader and mini-profiler
unless Conf.app_env == "production"
  # use Rack::Reloader, 1
  # use Rack::MiniProfiler
end

# Initialize workers
RestFtpDaemon::WorkerPool.instance.start_em_all

# Launch the API
run RestFtpDaemon::API::Root
