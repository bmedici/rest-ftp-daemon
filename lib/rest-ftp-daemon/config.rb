module RestFtpDaemon
  # Global config
  VERSION = "0.35"


  # Transfer config
  TRANSFER_CHUNK_SIZE = 100000
  THREAD_SLEEP_BEFORE_DIE = 600

  # Logging
  APP_LOGTO = "/tmp/#{APP_NAME}.log"
  LOG_TRIM_PROGNAME = 18

end
