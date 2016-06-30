require "securerandom"

module RestFtpDaemon

  # Reprensents work to be done along with parameters to process it
  class Job
    include Shared::LoggerHelper
    attr_reader :logger

    FIELDS = [:source, :target, :label, :priority, :pool, :notify, :overwrite, :mkdir, :tempfile]

    attr_accessor :wid

    attr_reader :id
    attr_reader :error
    attr_reader :status
    attr_reader :runs

    attr_reader :queued_at
    attr_reader :updated_at
    attr_reader :started_at
    attr_reader :finished_at

    attr_reader :infos
    attr_reader :pool

    attr_accessor :config
    attr_accessor :endpoints

    FIELDS.each do |name|
      attr_reader name
    end

    def initialize job_id, params = {}
      # Call super
      # super()

      # Init context
      @id = job_id.to_s
      # @infos = {}
      #@updated_at = nil
      @started_at = nil
      @finished_at = nil
      @error = nil
      @status = nil
      @runs = 0
      @wid = nil
      @config = {}
      @endpoints = {}

      # Logger
      @logger = RestFtpDaemon::LoggerPool.instance.get :jobs

      # Protect with a mutex
      @mutex = Mutex.new

      # Import query params
      FIELDS.each do |name|
        instance_variable_set "@#{name}", params[name]
      end

      # Set pool
      pools = (Conf[:pools] || {})
      # Check if pool name exists
      if (pools.keys.include? params[:pool])
        @pool = params[:pool].to_s
      else
        @pool = DEFAULT_POOL
      end

      # Set job queue, thus reset
      # reset
    end

    def reset
      # Flag current job
      @queued_at = Time.now
      @updated_at = Time.now

      # Send first notification
      log_info "Job.initialize notify[queued]}]"
      client_notify :queued

      # Update job status
      set_status JOB_STATUS_QUEUED
      set_error nil
      @infos = {}
    end

    def process
      log_info "Job.process update_interval[#{JOB_UPDATE_INTERVAL}]"

      # Prepare job
      begin
        prepare

      rescue RestFtpDaemon::JobMissingAttribute => exception
        return oops :started, exception, "missing_attribute"

      rescue RestFtpDaemon::JobUnresolvedTokens => exception
        return oops :started, exception, "unresolved_tokens"

      rescue RestFtpDaemon::JobTargetUnparseable => exception
        return oops :started, exception, "target_unparseable"

      rescue RestFtpDaemon::JobTargetUnsupported => exception
        return oops :started, exception, "target_unsupported"

      rescue RestFtpDaemon::JobAssertionFailed => exception
        return oops :started, exception, "assertion_failed"

      rescue URI::InvalidURIError => exception
        return oops :started, exception, "target_invalid"

      else
        # Prepare done !
        set_status JOB_STATUS_PREPARED
        log_info "Job.process notify [started]"
        client_notify :started
      end

      # Process job
      begin
        #return oops :ended, Exception.new, "ftp_perm_error"
        run

      rescue SocketError => exception
        return oops :ended, exception, "conn_socket_error"

      rescue EOFError => exception
        return oops :ended, exception, "conn_eof"

      rescue Errno::EHOSTDOWN => exception
        return oops :ended, exception, "conn_host_is_down"

      rescue Errno::EPIPE=> exception
        return oops :ended, exception, "conn_broken_pipe"

      rescue Errno::ENETUNREACH => exception
        return oops :ended, exception, "conn_unreachable"

      rescue Errno::ECONNRESET => exception
        return oops :ended, exception, "conn_reset_by_peer"

      rescue Errno::ENOTCONN => exception
        return oops :ended, exception, "conn_failed"

      rescue Errno::ECONNREFUSED => exception
        return oops :ended, exception, "conn_refused"

      rescue Timeout::Error, Errno::ETIMEDOUT, Net::ReadTimeout => exception
        return oops :ended, exception, "conn_timed_out"

      rescue OpenSSL::SSL::SSLError => exception
        return oops :ended, exception, "conn_openssl_error"

      rescue Net::FTPPermError => exception
        return oops :ended, exception, "ftp_perm_error"

      rescue Net::FTPTempError => exception
        return oops :ended, exception, "net_temp_error"

      rescue Net::SFTP::StatusException => exception
        return oops :ended, exception, "sftp_exception"

      rescue Net::SSH::HostKeyMismatch => exception
        return oops :ended, exception, "sftp_key_mismatch"

      rescue Net::SSH::AuthenticationFailed => exception
        return oops :ended, exception, "sftp_auth_failed"

      rescue Errno::EMFILE => exception
        return oops :ended, exception, "too_many_open_files"

      rescue Errno::EINVAL => exception
        return oops :ended, exception, "invalid_argument", true

      rescue Encoding::UndefinedConversionError => exception
        return oops :ended, exception, "encoding_error", true

      rescue RestFtpDaemon::JobSourceNotFound => exception
        return oops :ended, exception, "source_not_found"

      rescue RestFtpDaemon::JobSourceNotReadable => exception
        return oops :ended, exception, "source_not_readable"

      rescue RestFtpDaemon::JobTargetFileExists => exception
        return oops :ended, exception, "target_file_exists"

      rescue RestFtpDaemon::JobTargetDirectoryError => exception
        return oops :ended, exception, "target_directory_missing"

      rescue RestFtpDaemon::JobTargetPermissionError => exception
        return oops :ended, exception, "target_permission_error"

      rescue RestFtpDaemon::JobAssertionFailed => exception
        return oops :ended, exception, "assertion_failed"

      else
        # All done !
        set_status JOB_STATUS_FINISHED
        log_info "Job.process notify [ended]"
        client_notify :ended
      end
    end

    def weight
      @weight = [
        - @runs.to_i,
        + @priority.to_i,
        - @queued_at.to_i,
        ]
    end

    def exectime
      return nil if @started_at.nil? || @finished_at.nil?
      (@finished_at - @started_at).round(2)
    end

    def oops_after_crash exception
      oops :ended, exception, "crashed"
    end

    def oops_you_stop_now exception
      oops :ended, exception, "timeout"
    end

    def age
      return nil if @queued_at.nil?
      (Time.now - @queued_at).round(2)
    end

    def targethost
      get_info :target, :host
    end

    # def json_target
    #   utf8 get_info(:target, :method)
    # end

    def json_error
      utf8 @error unless @error.nil?
    end

    def json_status
      utf8 @status unless @status.nil?
    end

    def get_info level1, level2
      @mutex.synchronize do
        @infos || {}
        @infos[level1][level2] if @infos[level1].is_a? Hash
      end
    end

  protected

    def expand_path path
      File.expand_path replace_tokens(path)
    end

    def expand_url path
      URI.parse replace_tokens(path)
    end

    def contains_brackets item
      /\[.*\]/.match(item)
    end

    def replace_tokens path
      # Ensure endpoints are not a nil value
      return path unless @endpoints.is_a? Enumerable
      vectors = @endpoints.clone

      # Stack RANDOM into tokens
      vectors["RANDOM"] = SecureRandom.hex(JOB_RANDOM_LEN)

      # Replace endpoints defined in config
      newpath = path.clone
      vectors.each do |from, to|
        next if to.to_s.blank?
        newpath.gsub! Helpers.tokenize(from), to
      end

      # Ensure result does not contain tokens after replacement
      raise RestFtpDaemon::JobUnresolvedTokens if contains_brackets newpath

      # All OK, return this URL stripping multiple slashes
      newpath.gsub(/([^:])\/\//, '\1/')
    end

    def prepare
      # Init
      @source_path = nil

      # Prepare flags
      flag_prepare :mkdir, false
      flag_prepare :overwrite, false
      flag_prepare :tempfile, true

      # Update job status
      set_status JOB_STATUS_PREPARING
      @runs += 1

      # Prepare source
      raise RestFtpDaemon::JobMissingAttribute unless @source
      @source_path = expand_path @source
      set_info :source, :path, @source_path
      set_info :source, :method, JOB_METHOD_FILE

      # Prepare target
      raise RestFtpDaemon::JobMissingAttribute unless @target
      target_uri = expand_url @target
      set_info :target, :uri, target_uri.to_s
      set_info :target, :host, target_uri.host
      @target_path = Path.new target_uri.path, true

      #puts "@target_path: #{@target_path.inspect}"

      # Prepare remote
      #FIXME: use a "case" statement on @target_url.class

      if target_uri.is_a? URI::FTP
        log_info "Job.prepare target_method FTP"
        # set_info :target, :method, :ftp
        set_info :target, :method, JOB_METHOD_FTP
        #@target_method = :ftp
        @remote = RemoteFTP.new target_uri, log_prefix

      elsif (target_uri.is_a? URI::FTPES) || (target_uri.is_a? URI::FTPS)
        log_info "Job.prepare target_method FTPES"
        # set_info :target, :method, :ftpes
        set_info :target, :method, JOB_METHOD_FTPS
        # @target_method = :ftpes
        @remote = RemoteFTP.new target_uri, log_prefix, ftpes: true

      elsif target_uri.is_a? URI::SFTP
        log_info "Job.prepare target_method SFTP"
        # set_info :target, :method, :sftp
        set_info :target, :method, JOB_METHOD_SFTP
        # @target_method = :sftp
        @remote = RemoteSFTP.new target_uri, log_prefix

      else
        log_info "Job.prepare unknown scheme [#{target_uri.scheme}]"
        raise RestFtpDaemon::JobTargetUnsupported

      end
    end

    def run
      # Update job status
      set_status JOB_STATUS_RUNNING
      @started_at = Time.now

      # Method assertions and init
      raise RestFtpDaemon::JobAssertionFailed, "run/1" unless @source_path
      raise RestFtpDaemon::JobAssertionFailed, "run/2" unless @target_path
      @transfer_sent = 0
      set_info :source, :processed, 0

      # Guess source files from disk
      set_status JOB_STATUS_CHECKING_SRC
      sources = find_local @source_path
      set_info :source, :count, sources.count
      set_info :source, :files, sources.collect(&:full)
      log_info "Job.run sources #{sources.collect(&:name)}"
      raise RestFtpDaemon::JobSourceNotFound if sources.empty?

      # Guess target file name, and fail if present while we matched multiple sources
      raise RestFtpDaemon::JobTargetDirectoryError if @target_path.name && sources.count>1

      # Connect to remote server and login
      set_status JOB_STATUS_CONNECTING
      @remote.connect

      # Prepare target path or build it if asked
      set_status JOB_STATUS_CHDIR
      @remote.chdir_or_create @target_path.dir, @mkdir

      # Compute total files size
      @transfer_total = sources.collect(&:size).sum
      set_info :transfer, :total, @transfer_total

      # Reset counters
      @last_data = 0
      @last_time = Time.now

      # Handle each source file matched, and start a transfer
      source_processed = 0
      sources.each do |source|
        # Compute target filename
        full_target = @target_path.clone

        # Add the source file name if none found in the target path
        unless full_target.name
          full_target.name = source.name
        end

        # Do the transfer, for each file
        remote_push source, full_target

        # Update counters
        set_info :source, :processed, source_processed += 1
      end

      # FTP transfer finished
      finalize
    end

  private

    def log_prefix
     [@wid, @id, nil]
    end

    def find_local path
      Dir.glob(path).collect do |file|
        next unless File.readable? file
        next unless File.file? file
        Path.new file
      end
    end

    def touch_job
      now = Time.now
      @updated_at = now
      Thread.current.thread_variable_set :updated_at, now
    end

    def set_info level1, level2, value
      @mutex.synchronize do
        @infos || {}
        @infos[level1] ||= {}

        # Force strings to UTF8
        if value.is_a? Symbol
          @infos[level1][level2] = value.to_s.force_encoding(Encoding::UTF_8)
        elsif value.is_a? String
          @infos[level1][level2] = value.dup.force_encoding(Encoding::UTF_8)
        else
          @infos[level1][level2] = value
        end

        # Mark the job as updated
        touch_job
      end
    end

    def utf8 value
      value.to_s.encode("UTF-8")
    end

    def set_error value
      @error = value
      touch_job
    end

    def set_status value
      @status = value
      touch_job
    end

    def flag_prepare name, default
      # build the flag instance var name
      variable = "@#{name}"

      [config[name], default].each do |alt_value|
        # If it's already true or false, that's ok
        return if [true, false].include? instance_variable_get(variable)

        # Otherwise, set it to the new alt_value
        instance_variable_set variable, alt_value
      end
    end

    def finalize
      # Close FTP connexion and free up memory
      log_info "Job.finalize"
      @remote.close

      # Free-up remote object
      @remote = nil

      # Update job status
      set_status JOB_STATUS_DISCONNECTING
      @finished_at = Time.now

      # Update counters
      $counters.increment :jobs, :finished
      $counters.add :data, :transferred, @transfer_total
    end

    def remote_push source, target
      # Method assertions
      raise RestFtpDaemon::JobAssertionFailed, "remote_push/1" if @remote.nil?
      raise RestFtpDaemon::JobAssertionFailed, "remote_push/2" if source.nil?
      raise RestFtpDaemon::JobAssertionFailed, "remote_push/3" if target.nil?

      # Use source filename if target path provided none (typically with multiple sources)
      log_info "Job.remote_push [#{source.name}]: [#{source.full}] > [#{target.full}]"
      set_info :source, :current, source.name

      # Compute temp target name
      tempname = nil
      if @tempfile
        tempname = "#{target.name}.temp-#{Helpers.identifier(JOB_TEMPFILE_LEN)}"
        log_debug "Job.remote_push tempname [#{tempname}]"
      end

      # Remove any existing version if expected, or test its presence
      if @overwrite
        @remote.remove! target
      elsif size = @remote.present?(target)
        log_debug "Job.remote_push existing (#{Helpers.format_bytes size, 'B'})"
        raise RestFtpDaemon::JobTargetFileExists
      end

      # Start transfer
      transfer_started_at = Time.now
      @progress_at = 0
      @notified_at = transfer_started_at

      # Start the transfer, update job status after each block transfer
      set_status JOB_STATUS_UPLOADING
      @remote.push source, target, tempname do |transferred, name|
        # Update transfer statistics
        progress transferred, name

        # Touch my worker status
        touch_job
      end

      # Compute final bitrate
      global_transfer_bitrate = get_bitrate @transfer_total, (Time.now - transfer_started_at)
      set_info :transfer, :bitrate, global_transfer_bitrate.round(0)

      # Done
      set_info :source, :current, nil
    end

    def progress transferred, name = ""
      # What's current time ?
      now = Time.now
      notify_after_sec = @config[:notify_after_sec]

      # Update counters
      @transfer_sent += transferred
      set_info :transfer, :sent, @transfer_sent

      # Update job info
      percent0 = (100.0 * @transfer_sent / @transfer_total).round(0)
      set_info :transfer, :progress, percent0

      # Update job status after each NOTIFY_UPADE_STATUS
      progressed_ago = (now.to_f - @progress_at.to_f)
      if (!JOB_UPDATE_INTERVAL.to_f.zero?) && (progressed_ago > JOB_UPDATE_INTERVAL.to_f)
        @current_bitrate = running_bitrate @transfer_sent
        set_info :transfer, :bitrate, @current_bitrate.round(0)

        # Log progress
        stack = []
        stack << "#{percent0} %"
        stack << (Helpers.format_bytes @transfer_sent, "B")
        stack << (Helpers.format_bytes @transfer_total, "B")
        stack << (Helpers.format_bytes @current_bitrate.round(0), "bps")
        stack2 = stack.map { |txt| ("%#{LOG_PIPE_LEN.to_i}s" % txt) }.join("\t")
        log_debug "Job.progress #{stack2} \t#{name}"

        # Remember when we last did it
        @progress_at = now
      end

      # Notify if requested
      notified_ago = (now.to_f - @notified_at.to_f)
      if (!notify_after_sec.nil?) && (notified_ago > notify_after_sec)
        # Prepare and send notification
        notif_status = {
          progress: percent0,
          transfer_sent: @transfer_sent,
          transfer_total: @transfer_total,
          transfer_bitrate: @current_bitrate,
          }
        client_notify :progress, status: notif_status

        # Remember when we last did it
        @notified_at = now
      end
    end

    def client_notify event, payload = {}
      # Skip if no URL given
      return unless @notify

      # Ok, create a notification!
      payload[:id] = @id
      payload[:event] = event
      RestFtpDaemon::Notification.new @notify, payload

    rescue StandardError => ex
      log_error "Job.client_notify EXCEPTION: #{ex.inspect}"
    end

    def get_bitrate delta_data, delta_time
      return nil if delta_time.nil? || delta_time.zero?
      8 * delta_data.to_f.to_f / delta_time
    end

    def running_bitrate current_data
      return if @last_time.nil?

      # Compute deltas
      @last_data ||= 0
      delta_data = current_data - @last_data
      delta_time = Time.now - @last_time

      # Update counters
      @last_time = Time.now
      @last_data = current_data

      # Return bitrate
      get_bitrate delta_data, delta_time
    end

    def oops event, exception, error = nil, include_backtrace = false
      # Log this error
      # error = exception.class.to_s.encoding.to_s if error.nil?
      error = exception.class if error.nil?
      # error = "DEF #{exception.class}" if error.nil?

      message = "Job.oops event[#{event}] error[#{error}] ex[#{exception.class}] #{exception.message}"
      if include_backtrace
        log_error message, exception.backtrace
      else
        log_error message
      end

      # Close ftp connexion if open
      @remote.close unless @remote.nil? || !@remote.connected?

      # Update job's internal status
      set_status JOB_STATUS_FAILED
      set_error error
      set_info :error, :exception, exception.class.to_s
      set_info :error, :message, exception.message

      # Build status stack
      notif_status = nil
      if include_backtrace
        set_info :error, :backtrace, exception.backtrace
        notif_status = {
          backtrace: exception.backtrace,
          }
      end

      # Increment counter for this error
      $counters.increment :errors, error
      $counters.increment :jobs, :failed

      # Prepare notification if signal given
      return unless event
      client_notify event, error: error, status: notif_status, message: "#{exception.class} | #{exception.message}"
    end

    # NewRelic instrumentation
    if Conf.newrelic_enabled?
      include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
      add_transaction_tracer :prepare,        category: :task
      add_transaction_tracer :run,            category: :task
      add_transaction_tracer :client_notify,  category: :task
      add_transaction_tracer :initialize,     category: :task
    end

  end
end
