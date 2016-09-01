require "securerandom"
require "double_bag_ftps"
require "net/ssh"
require "net/ftp"
require "net/sftp"
require 'streamio-ffmpeg'

module RestFtpDaemon
  class Job

    # Common errors
    ERRORS = {
      invalid_argument:     Errno::EINVAL,

      conn_socket_error:    SocketError,
      conn_eof:             EOFError,
      conn_failed:          Errno::ENOTCONN,
      conn_host_is_down:    Errno::EHOSTDOWN,
      conn_broken_pipe:     Errno::EPIPE,
      conn_unreachable:     Errno::ENETUNREACH,
      conn_reset_by_peer:   Errno::ECONNRESET,
      conn_failed:          Errno::ENOTCONN,
      conn_refused:         Errno::ECONNREFUSED,
      conn_timed_out_1:     Timeout::Error,
      conn_timed_out_2:     Net::ReadTimeout,
      conn_timed_out_3:     Errno::ETIMEDOUT,

      ftp_connection_error: Net::FTPConnectionError,
      ftp_perm_error:       Net::FTPPermError,
      ftp_reply_error:      Net::FTPReplyError,
      ftp_temp_error:       Net::FTPTempError,
      ftp_proto_error:      Net::FTPProtoError,
      ftp_error:            Net::FTPError,

      ffmpeg_error:         FFMPEG::Error,

      # sftp_exception:       Net::SFTP::StatusException,
      # sftp_key_mismatch:    Net::SFTP::HostKeyMismatch,
      # sftp_auth_failed:     Net::SFTP::AuthenticationFailed,
      sftp_openssl_error:   OpenSSL::SSL::SSLError,
      # rescue Encoding::UndefinedConversionError => exception
      #   return oops :ended, exception, "encoding_error", true
      }

  end
end
