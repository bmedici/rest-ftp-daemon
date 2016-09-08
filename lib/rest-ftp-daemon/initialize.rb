# Init Rollbar and Newrelic
Conf.prepare_newrelic
Conf.prepare_rollbar
# Initialize workers
Conf.log :init, "init: workers"
RestFtpDaemon::WorkerPool.instance.start_em_all

