require 'settingslogic'

# Terrific assertions
#raise "config.rb: APP_ROOT is not defined" unless defined? APP_ROOT
APP_NAME = "rest-ftp-daemon"
APP_CONF = "/etc/#{APP_NAME}.yml"
APP_DEV = ARGV.include?("development") ? true : false

class Settings < Settingslogic
  # Read configuration
  source (File.exists? APP_CONF) ? APP_CONF : Hash.new
  namespace (APP_DEV ? "development" : "production")
  suppress_errors true

  # Some constants
  self[:dev] = APP_DEV
  self[:app_name] = APP_NAME
  self[:app_lib] = File.expand_path File.dirname(__FILE__)
  self[:app_ver] = "0.72b"
  self[:app_started] = Time.now
  self[:default_trim_progname] = "18"

  # Some defaults
  self[:default_chunk_size] = "1000000"
  self[:default_notify_size] = "10000000"
end
