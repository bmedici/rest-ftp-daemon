# Init Rollbar
Conf.prepare_rollbar

# Initialize Facter
Conf.log :initialize, "prepare Facter"
begin
  Facter.loadfacts
rescue StandardError => exception
  Conf.log :initialize, "facter failed to initialize: #{exception.message}"
end

# Detect plugins
plugins = Pluginator.
	find(Conf.app_name)
Conf.log :initialize, "detected remotes: #{plugins[PLUGIN_REMOTE].inspect}"
Conf.log :initialize, "detected transforms: #{plugins[PLUGIN_TRANSFORM].inspect}"

# Initialize workers
Conf.log :initialize, "start workers"
RestFtpDaemon::WorkerPool.instance.start_em_all