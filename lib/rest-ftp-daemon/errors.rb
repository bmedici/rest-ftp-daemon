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

    source_not_supported:     RestFtpDaemon::SourceUnsupported,
    source_not_found:         RestFtpDaemon::SourceNotFound,
    source_should_be_unique:  RestFtpDaemon::SourceShouldBeUnique,

    target_file_exists:       RestFtpDaemon::TargetFileExists,
    target_directory_error:   RestFtpDaemon::TargetDirectoryError,
    target_permission_error:  RestFtpDaemon::TargetPermissionError,
    target_not_supported:     RestFtpDaemon::TargetUnsupported,
    target_name_required:     RestFtpDaemon::TargetNameRequired,
    task_failed:              RestFtpDaemon::TaskFailed,

    conn_failed_1:            Errno::ENOTCONN,
    conn_failed_2:            Errno::EHOSTUNREACH,
    conn_failed_3:            Errno::ENETUNREACH,
    conn_failed_4:            Errno::EHOSTDOWN,
    conn_failed_5:            Errno::ECONNREFUSED,
    conn_failed_6:            SocketError,
    conn_interrupted_1:       EOFError,
    conn_interrupted_2:       Errno::EPIPE,
    conn_interrupted_3:       Errno::ECONNRESET,
    conn_timed_out_1:         Timeout::Error,
    conn_timed_out_2:         Net::ReadTimeout,
    conn_timed_out_3:         Errno::ETIMEDOUT,

    ftp_connection_error:     Net::FTPConnectionError,
    ftp_perm_error:           Net::FTPPermError,
    ftp_reply_error:          Net::FTPReplyError,
    ftp_temp_error:           Net::FTPTempError,
    ftp_proto_error:          Net::FTPProtoError,
    ftp_error:                Net::FTPError,

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