require 'settingslogic'
DEVELOPMENT = false unless defined? DEVELOPMENT

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
Settings[:name] = APP_NAME
Settings[:version] = 0.58

# Forced fixed settings
Settings[:default_trim_progname] = "18"
Settings[:default_chunk_size] = "1000000"
