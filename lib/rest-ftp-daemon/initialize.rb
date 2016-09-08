# Init Rollbar and Newrelic
Conf.log :init, "init: Newrelic and Rollbar"
Conf.prepare_newrelic
Conf.prepare_rollbar

# Initialize Facter
Conf.log :init, "init: Facter"
begin
  Facter.loadfacts
rescue StandardError => exception
  Conf.log :init, "init: Facter failed to initialize: #{exception.message}"
end

# Initialize workers
Conf.log :init, "init: workers"
RestFtpDaemon::WorkerPool.instance.start_em_all

