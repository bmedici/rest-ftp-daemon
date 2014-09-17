require 'settingslogic'
DEVELOPMENT = false unless defined? DEVELOPMENT
CONFIG_FILE = "/etc/rest-ftp-daemon.yml"

class Settings < Settingslogic
  # source "/etc/#{RestFtpDaemon::NAME}.yml"
  namespace DEVELOPMENT ? "development" : "production"
  #suppress_errors namespace=="development"
  suppress_errors true
  # !DEVELOPMENT
end

# Fix application defaults and load config file if found
if File.exists? CONFIG_FILE
  Settings.source CONFIG_FILE
else
  Settings.source Hash.new
end

# Forced shared settings
Settings[:name] = "rest-ftp-daemon"
Settings[:version] = 0.50

# Forced fixed settings
Settings[:default_trim_progname] = "18"
Settings[:default_chunk_size] = "1000000"

