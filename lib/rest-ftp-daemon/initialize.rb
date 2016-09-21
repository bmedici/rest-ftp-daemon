# Init Rollbar
Conf.prepare_rollbar

# Initialize Facter
Conf.log :initialize, "prepare Facter"
begin
  Facter.loadfacts
rescue StandardError => exception
  Conf.log :initialize, "facter failed to initialize: #{exception.message}"
end

# Initialize workers
Conf.log :initialize, "prepare workers"
RestFtpDaemon::WorkerPool.instance.start_em_all
