# Try to load Settingslogic
begin
  require "settingslogic"
rescue LoadError
  raise "warning: Settingslogic is needed to provide configuration values to the Gemspec file"
end

# Configuration class
class Settings < Settingslogic
  # Read configuration
  namespace (defined?(APP_ENV) ? APP_ENV : "production")
  source ((File.exists? APP_CONF) ? APP_CONF : Hash.new)
  suppress_errors true

  # Compute my PID filename
  def pidfile
    self["pidfile"] || "/tmp/#{APP_NAME}.port#{self['port'].to_s}.pid"
  end

  # Direct access to any depth
  def at *path
    path.reduce(Settings) {|m,key| m && m[key.to_s] }
  end

  # Dump whole settings set to readable YAML
  def dump
    self.to_hash.to_yaml( :Indent => 4, :UseHeader => true, :UseVersion => false )
  end

  def newrelic_enabled?
    Settings.newrelic.is_a?(Hash) && Settings.at(:newrelic, :license)
  end

  def init_newrelic
    # Skip if not enabled
    return ENV['NEWRELIC_AGENT_ENABLED'] = 'false' unless Settings.newrelic_enabled?

    # Enable module
    ENV['NEWRELIC_AGENT_ENABLED'] = 'true'
    ENV['NEW_RELIC_MONITOR_MODE'] = 'true'
    #Settings['newrelic']['enabled'] = true

    # License
    ENV['NEW_RELIC_LICENSE_KEY'] = Settings.at(:newrelic, :license)

    # Appname
    ENV['NEW_RELIC_APP_NAME'] = Settings.at(:newrelic, :appname) || "#{APP_NICK}-#{Settings.host}-#{APP_ENV}"

    # Logfile
    ENV['NEW_RELIC_LOG'] = Settings.at(:logs, :newrelic)

  end

end
