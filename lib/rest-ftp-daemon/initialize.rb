# Init Rollbar and Newrelic
Conf.prepare_newrelic
Conf.prepare_rollbar

# Initialize Facter
Conf.log :initialize, "Facter"
begin
  Facter.loadfacts
rescue StandardError => exception
  Conf.log :initialize, "facter failed to initialize: #{exception.message}"
end

# Initialize workers
Conf.log :initialize, "workers"
RestFtpDaemon::WorkerPool.instance.start_em_all

