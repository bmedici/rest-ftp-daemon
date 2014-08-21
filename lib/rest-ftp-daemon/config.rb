module RestFtpDaemon
  # Global config
  VERSION = "0.22"

  ERRORS = {
    ERR_JOB_SOURCE_NOTFOUND: 21,
    ERR_JOB_TARGET_UNPARSEABLE: 22,
  }

  # Transfer config
  TRANSFER_CHUNK_SIZE = 100000
  THREAD_SLEEP_BEFORE_DIE = 360
  #THREAD_SLEEP_BEFORE_DIE = 120

  # Errors: global
  ERR_OK                            = 0
  ERR_BUSY                          = -1

  # Errors at request level
  ERR_REQ_SOURCE_MISSING            = 11
  ERR_REQ_TARGET_MISSING            = 12
  ERR_REQ_SOURCE_NOTFOUND           = 13
  ERR_REQ_TARGET_SCHEME             = 15

  # Errors at job level
  ERR_JOB_SOURCE_NOTFOUND            = 21
  ERR_JOB_TARGET_UNPARSEABLE         = 22
  ERR_JOB_PERMISSION                 = 24
  ERR_JOB_TARGET_PRESENT             = 25

end
