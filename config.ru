# FIXME: Newrelic agent bug: we have to define the logfile early
Conf.prepare_newrelic

# Load code
Conf.log :rackup, "load project code"

load_path_libs = File.expand_path "lib", File.dirname(__FILE__)
$LOAD_PATH.unshift(load_path_libs) unless $LOAD_PATH.include?(load_path_libs)
require "rest-ftp-daemon"

# Rack authent
Conf.log :rackup, "authentication, assets, env-specific"
unless Conf[:adminpwd].nil?
  use Rack::Auth::Basic, "Restricted Area" do |username, password|
    [username, password] == ["admin", Conf[:adminpwd]]
  end
end

# Serve static assets
use Rack::Static, root: "#{Conf.app_libs}/public/", urls: [
  "/css/",
  "/js/",
  "/fonts/",
  "/images/",
  "/swagger/",
  MOUNT_SWAGGER_UI,
  ]

# Env-specific configuration
case Conf.app_env
  when "development"
    # Rack reloader
    use Rack::Reloader, 1

  when "production"
end

# Load plugins
require 'pluginator'
plugins = Pluginator.find('rest-ftp-daemon')
Conf.log :plugins, "types: #{plugins.types.inspect}"
Conf.log :plugins, "remote: #{plugins[:remote].inspect}"
Conf.log :plugins, "transform: #{plugins[:transform].inspect}"

# Launch the API
Conf.log :rackup, "start API::Root"
run RestFtpDaemon::API::Root

