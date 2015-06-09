# Configuration class
class Settings < Settingslogic
  # Read configuration
  namespace (defined?(APP_ENV) ? APP_ENV : "production")
  source ((File.exists? APP_CONF) ? APP_CONF : Hash.new)
  suppress_errors true

  # Compute my PID filename
  def pidfile
    self['pidfile'] || "/tmp/#{APP_NAME}.port#{self['port'].to_s}.pid"
  end

  # Direct access to any depth
  def at *path
    path.reduce(Settings) {|m,key| m && m[key.to_s] }
  end

  # Dump whole settings set to readable YAML
  def dump
    self.to_hash.to_yaml(indent: 4, useheader: true, useversion: false )
  end

  def init_defaults
    Settings['host'] ||= `hostname`.chomp.split('.').first
  end

  def newrelic_enabled?
    Settings.at(:debug, :newrelic)
  end

  def init_newrelic
    # Skip if not enabled
    return ENV['NEWRELIC_AGENT_ENABLED'] = 'false' unless Settings.newrelic_enabled?

    # Enable module
    ENV['NEWRELIC_AGENT_ENABLED'] = 'true'
    ENV['NEW_RELIC_MONITOR_MODE'] = 'true'
    #Settings['newrelic']['enabled'] = true

    # License
    ENV['NEW_RELIC_LICENSE_KEY'] = Settings.at(:debug, :newrelic)

    # Appname
    ENV['NEW_RELIC_APP_NAME'] = "#{APP_NICK}-#{Settings.host}-#{APP_ENV}"

    # Logfile
    ENV['NEW_RELIC_LOG'] = Settings.at(:logs, :newrelic)
  end

end
