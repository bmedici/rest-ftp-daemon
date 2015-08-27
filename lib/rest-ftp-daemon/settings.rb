require "settingslogic"

# Configuration class
class Settings < Settingslogic
  # Read configuration
  namespace APP_ENV
  source File.exist?(APP_CONF) ? APP_CONF : Hash.new
  suppress_errors true

  # Direct access to any depth
  def at *path
    path.reduce(Settings) { |m, key| m && m[key.to_s] }
  end

  # Dump whole settings set to readable YAML
  def dump
    to_hash.to_yaml(indent: 4, useheader: true, useversion: false )
  end

  def newrelic_enabled?
    Settings.at(:newrelic)
  end

  def init_defaults
    # Init host if missing
    Settings["host"] ||= `hostname`.to_s.chomp.split(".").first

    # Init PID file name if missing
    Settings["pidfile"] ||= "/tmp/#{APP_NICK}-#{Settings['host']}-#{Settings['port']}.pid"

    # Init NEWRELIC env
    if Settings.newrelic_enabled?
      # Enable module
      ENV["NEWRELIC_AGENT_ENABLED"] = "true"
      ENV["NEW_RELIC_MONITOR_MODE"] = "true"

      # License
      ENV["NEW_RELIC_LICENSE_KEY"] = Settings.at(:newrelic, :licence)

      # Appname
      platform = Settings.newrelic[:platform] || Settings["host"]
      Settings.newrelic[:app_name] ||= "#{APP_NICK}-#{platform}-#{Settings.namespace}"
      ENV["NEW_RELIC_APP_NAME"] = Settings.newrelic[:app_name]

      # Logfile
      ENV["NEW_RELIC_LOG"] = Settings.at(:logs, :newrelic)
    else
      ENV["NEWRELIC_AGENT_ENABLED"] = "false"
    end

    # That's it!
  end

  def overwrite options
    Settings.merge!(options) if options.is_a? Enumerable
  end

end
