# Try to load Settingslogic
begin
  require "settingslogic"
rescue LoadError
  raise "config.rb warning: Settingslogic is needed to provide configuration values to the Gemspec file"
end

# Configuration class
class Settings < Settingslogic
  # Read configuration
  namespace (defined?(APP_ENV) ? APP_ENV : "production")
  source ((File.exists? APP_CONF) ? APP_CONF : Hash.new)
  suppress_errors true


end

