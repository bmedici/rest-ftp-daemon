module RestFtpDaemon

  # Common errors
  JOB_ERRORS = {
    # oops_invalid_argument:         Errno::EINVAL,
    oops_runtime_error:       RuntimeError,

    assertion_failed:         RestFtpDaemon::AssertionFailed,
    location_parse_error:     RestFtpDaemon::LocationParseError,

    job_timeout:              RestFtpDaemon::JobTimeout,
    job_unknwown_transform:   RestFtpDaemon::JobUnknownTransform,
    job_attribute_missing:    RestFtpDaemon::JobAttributeMissing,

    conn_timed_out_1:         Timeout::Error,
    conn_timed_out_2:         Net::ReadTimeout,
    conn_timed_out_3:         Errno::ETIMEDOUT,

    sftp_exception:           Net::SFTP::StatusException,
    sftp_key_mismatch:        Net::SSH::HostKeyMismatch,
    sftp_auth_failed:         Net::SSH::AuthenticationFailed,
    sftp_openssl_error:       OpenSSL::SSL::SSLError,

    s3_no_such_waiter:        Aws::Waiters::Errors::NoSuchWaiterError,
    s3_failure_state_error:   Aws::Waiters::Errors::FailureStateError,
    s3_too_many_attempts:     Aws::Waiters::Errors::TooManyAttemptsError,
    s3_waiter_unexpected:     Aws::Waiters::Errors::UnexpectedError,
    s3_waiter_failed:         Aws::Waiters::Errors::WaiterFailed,

    s3_not_found:             Aws::S3::Errors::NotFound,
    s3_permanent_redirect:    Aws::S3::Errors::PermanentRedirect,
    s3_no_such_key:           Aws::S3::Errors::NoSuchKey,
    s3_no_such_bucket:        Aws::S3::Errors::NoSuchBucket,
    s3_no_such_upload:        Aws::S3::Errors::NoSuchUpload,
    s3_error:                 Aws::S3::Errors::ServiceError,

    transform_missing_binary: RestFtpDaemon::TransformMissingBinary,
    transform_video_error:    RestFtpDaemon::TransformVideoError,
    transform_ffmpeg_error:   FFMPEG::Error,
    }

end