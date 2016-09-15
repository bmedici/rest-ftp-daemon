# Load gem files
Conf.log :rackup, "load project code"

load_path_libs = File.expand_path "lib", File.dirname(__FILE__)
$LOAD_PATH.unshift(load_path_libs) unless $LOAD_PATH.include?(load_path_libs)
require "rest-ftp-daemon"

# Rack authent
Conf.log :rackup, "rackup: rack setup"
unless Conf[:adminpwd].nil?
  use Rack::Auth::Basic, "Restricted Area" do |username, password|
    [username, password] == ["admin", Conf[:adminpwd]]
  end
end

# Serve static assets
use Rack::Static, root: "#{Conf.app_libs}/static/", urls: [
  "/css/",
  "/js/",
  "/fonts/",
  "/images/",
  "/swagger/",
  MOUNT_SWAGGER_UI,
  ]

# Rack reloader
if Conf.app_env == "development"
  # use Rack::Reloader, 1
end

# Launch the API
Conf.log :rackup, "start API::Root"
run RestFtpDaemon::API::Root

