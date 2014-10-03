require 'settingslogic'
DEVELOPMENT = false unless defined? DEVELOPMENT
APP_NAME="rest-ftp-daemon"

class Settings < Settingslogic
  namespace DEVELOPMENT ? "development" : "production"
  suppress_errors namespace!="development"
end

# Fix application defaults and load config file if found
app_config_file = "/etc/#{APP_NAME}.yml"
if File.exists? app_config_file
  Settings.source app_config_file
else
  Settings.source Hash.new
end

# Forced shared settings
Settings[:app_name] = APP_NAME
Settings[:app_root] = APP_ROOT if defined? APP_ROOT
Settings[:app_ver] = "0.63"

# Forced fixed settings
Settings[:app_trim_progname] = "18"
Settings[:app_chunk_size] = "1000000"
