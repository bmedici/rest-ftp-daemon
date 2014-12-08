require 'uri'
require 'net/ftp'
require 'double_bag_ftps'
require 'timeout'

module RestFtpDaemon
  class Job < RestFtpDaemon::Common

    FIELDS = [:source, :target, :priority, :notify, :overwrite, :mkdir]

    attr_reader :id
    attr_accessor :wid

    attr_reader :error
    attr_reader :status

    attr_reader :queued_at
    attr_reader :updated_at

    attr_reader :params

    FIELDS.each do |field|
      attr_reader field
    end

    def initialize job_id, params={}
      # Call super
      # super()
      info "Job.initialize"

      # Init context
      @id = job_id.to_s
      #set :id, job_id
      FIELDS.each do |field|
        instance_variable_set("@#{field.to_s}", params[field])
      end
      @params = {}

      # Protect with a mutex
      @mutex = Mutex.new

      # Logger
      @logger = RestFtpDaemon::Logger.new(:workers, "JOB #{id}")

      # Flag current job
      @queued_at = Time.now
      @status = :created

      # Send first notification
      #info "Job.initialize/notify"
      client_notify "rftpd.queued"
    end

    def close
      # Close logger
      info "Job.close"
      @logger.close
    end

    def process
      # Update job's status
      @error = nil

      # Prepare job
      begin
        info "Job.process prepare"
        @status = :preparing
        prepare

      rescue RestFtpDaemon::JobMissingAttribute => exception
        return oops "rftpd.started", exception, :job_missing_attribute

      # rescue RestFtpDaemon::JobSourceNotFound => exception
      #   return oops "rftpd.started", exception, :job_source_not_found

      rescue RestFtpDaemon::JobUnresolvedTokens => exception
        return oops "rftpd.started", exception, :job_unresolved_tokens

      rescue RestFtpDaemon::JobTargetUnparseable => exception
        return oops "rftpd.started", exception, :job_target_unparseable

      rescue RestFtpDaemon::JobTargetUnsupported => exception
        return oops "rftpd.started", exception, :job_target_unsupported

      rescue RestFtpDaemon::JobAssertionFailed => exception
        return oops "rftpd.started", exception, :job_assertion_failed

      rescue RestFtpDaemon::RestFtpDaemonException => exception
        return oops "rftpd.started", exception, :job_prepare_failed

      rescue URI::InvalidURIError => exception
        return oops "rftpd.started", exception, :job_target_invalid

      rescue Exception => exception
        return oops "rftpd.started", exception, :job_prepare_unhandled, true

      else
        # Prepare done !
        @status = :prepared
        info "Job.process notify rftpd.started"
        client_notify "rftpd.started", nil
      end

      # Process job
      begin
        info "Job.process transfer"
        @status = :starting
        transfer

      rescue Errno::EHOSTDOWN => exception
        return oops "rftpd.ended", exception, :job_host_is_down

      rescue Errno::ECONNREFUSED => exception
        return oops "rftpd.ended", exception, :job_connexion_refused

      rescue Timeout::Error, Errno::ETIMEDOUT => exception
        return oops "rftpd.ended", exception, :job_timeout

      rescue Net::FTPPermError => exception
        return oops "rftpd.ended", exception, :job_perm_error

      rescue OpenSSL::SSL::SSLError => exception
        return oops "rftpd.ended", exception, :job_openssl_error

      rescue Errno::EMFILE => exception
        return oops "rftpd.ended", exception, :job_too_many_open_files

      rescue RestFtpDaemon::JobSourceNotFound => exception
        return oops "rftpd.ended", exception, :job_source_not_found

      rescue RestFtpDaemon::JobTargetFileExists => exception
        return oops "rftpd.ended", exception, :job_target_file_exists

      rescue RestFtpDaemon::JobTargetShouldBeDirectory => exception
        return oops "rftpd.ended", exception, :job_target_should_be_directory

      rescue RestFtpDaemon::JobAssertionFailed => exception
        return oops "rftpd.started", exception, :job_assertion_failed

      rescue RestFtpDaemon::RestFtpDaemonException => exception
        return oops "rftpd.ended", exception, :job_transfer_failed

      rescue Exception => exception
        return oops "rftpd.ended", exception, :job_transfer_unhandled, true

      else
        # All done !
        @status = :finished
        info "Job.process notify rftpd.ended"
        client_notify "rftpd.ended", nil
      end

    end

    def get attribute
      @mutex.synchronize do
        @params || {}
        @params[attribute]
      end
    end

    def set_queued
      @status = :queued
    end

  protected

    def age
      return 0 if @queued_at.nil?
      (Time.now - @queued_at).round(2)
    end

    def wander time
      info "Job.wander #{time}"
      @wander_for = time
      @wander_started = Time.now
      sleep time
      info "Job.wandered ok"
    end

    def wandering_time
      return if @wander_started.nil? || @wander_for.nil?
      @wander_for.to_f - (Time.now - @wander_started)
    end

    def set attribute, value
      @mutex.synchronize do
        @params || {}
        # return unless @params.is_a? Enumerable
        @updated_at = Time.now
        @params[attribute] = value
      end
    end

    def expand_path path
      File.expand_path replace_tokens(path)
    end

    def expand_url path
      URI::parse replace_tokens(path)
    end

    def contains_brackets(item)
      /\[.*\]/.match(item)
    end

    def replace_tokens path
      # Ensure endpoints are not a nil value
      return path unless Settings.endpoints.is_a? Enumerable
      vectors = Settings.endpoints.clone

      # Stack RANDOM into tokens
      vectors['RANDOM'] = SecureRandom.hex(IDENT_RANDOM_LEN)

      # Replace endpoints defined in config
      newpath = path.clone
      vectors.each do |from, to|
        next if to.to_s.blank?
        newpath.gsub! Helpers.tokenize(from), to
      end

      # Ensure result does not contain tokens after replacement
      raise RestFtpDaemon::JobUnresolvedTokens if contains_brackets newpath

      # All OK, return this URL stripping multiple slashes
      return newpath.gsub(/([^:])\/\//, '\1/')
    end

    def prepare
      # Init
      @status = :preparing
      @source_method = :file
      @target_method = nil
      @source_path = nil
      @target_url = nil

      # Check source
      raise RestFtpDaemon::JobMissingAttribute unless @source
      @source_path = expand_path @source
      set :source_path, @source_path
      set :source_method, :file

      # Check target
      raise RestFtpDaemon::JobMissingAttribute unless @target
      @target_url = expand_url @target
      set :target_url, @target_url.to_s

      if @target_url.kind_of? URI::FTP
        @target_method = :ftp
      elsif @target_url.kind_of? URI::FTPES
        @target_method = :ftps
      elsif @target_url.kind_of? URI::FTPS
        @target_method = :ftps
      end
      set :target_method, @target_method

      # Check compliance
      raise RestFtpDaemon::JobTargetUnparseable if @target_url.nil?
      raise RestFtpDaemon::JobTargetUnsupported if @target_method.nil?
    end

    def transfer
      # Method assertions and init
      @status = :checking_source
      raise RestFtpDaemon::JobAssertionFailed unless @source_path && @target_url
      @transfer_sent = 0
      set :source_processed, 0

      # Guess source file names using Dir.glob
      source_matches = Dir.glob @source_path
      info "Job.transfer sources #{source_matches.inspect}"
      raise RestFtpDaemon::JobSourceNotFound if source_matches.empty?
      set :source_count, source_matches.count
      set :source_files, source_matches

      # Guess target file name, and fail if present while we matched multiple sources
      target_name = Helpers.extract_filename @target_url.path
      raise RestFtpDaemon::JobTargetShouldBeDirectory if target_name && source_matches.count>1

      # Scheme-aware config
      ftp_init

      # Connect remote server, login and chdir
      ftp_connect_and_login

      # Connect remote server, login and chdir
      #path = '/' + Helpers.extract_dirname(@target_url.path).to_s
      path = Helpers.extract_dirname(@target_url.path).to_s
      ftp_chdir_or_buildpath path

      # Check source files presence and compute total size, they should be there, coming from Dir.glob()
      @transfer_total = 0
      source_matches.each do |filename|
        # @ftp.close
        raise RestFtpDaemon::JobSourceNotFound unless File.exists? filename
        @transfer_total += File.size filename
      end
      set :transfer_total, @transfer_total

      # Handle each source file matched, and start a transfer
      done = 0
      source_matches.each do |filename|
        ftp_transfer filename, target_name
        done += 1
        set :source_processed, done
      end

      # Add total transferred to counter
      $queue.counter_add :transferred, @transfer_total

      # Close FTP connexion
      info "Job.transfer disconnecting"
      @status = :disconnecting
      @ftp.close
    end

  private

    def oops signal_name, exception, error_name = nil, include_backtrace = false
      # Log this error
      error_name = exception.class if error_name.nil?
      info "Job.oops si[#{signal_name}] er[#{error_name.to_s}] ex[#{exception.class}]"

      # Update job's internal status
      @status = :failed
      @error = error_name
      set :error_name, error_name
      set :error_exception, exception.class
      set :error_message, exception.message

      # Build status stack
      notif_status = nil
      if include_backtrace
        set :error_backtrace, exception.backtrace
        notif_status = {
          backtrace: exception.backtrace,
        }
      end

      # Increment counter for this error
      $queue.counter_inc "err_#{error_name}"
      $queue.counter_inc :jobs_failed

      # Prepare notification if signal given
      return unless signal_name
      client_notify signal_name, error_name, notif_status
    end

    def ftp_init
      # Method assertions
      info "Job.ftp_init asserts"
      @status = :ftp_init
      raise RestFtpDaemon::JobAssertionFailed if @target_method.nil? || @target_url.nil?

      info "Job.ftp_init target_method [#{@target_method}]"
      case @target_method
      when :ftp
        @ftp = Net::FTP.new
      when :ftps
        @ftp = DoubleBagFTPS.new
        @ftp.ssl_context = DoubleBagFTPS.create_ssl_context(:verify_mode => OpenSSL::SSL::VERIFY_NONE)
        @ftp.ftps_mode = DoubleBagFTPS::EXPLICIT
      else
        info "Job.transfer unknown scheme [#{@target_url.scheme}]"
        railse RestFtpDaemon::JobTargetUnsupported
      end

      # Common setup
      @ftp.debug_mode = DEBUG_FTP_COMMANDS
      @ftp.passive = true
    end

    def ftp_connect_and_login
      #@status = :ftp_connect
      # connect_timeout_sec = (Settings.transfer.connect_timeout_sec rescue nil) || DEFAULT_CONNECT_TIMEOUT_SEC

      # Method assertions
      host = @target_url.host
      info "Job.ftp_connect connect [#{host}]"
      @status = :ftp_connect
      raise RestFtpDaemon::JobAssertionFailed if @ftp.nil? || @target_url.nil?
      @ftp.connect(host)

      @status = :ftp_login
      info "Job.ftp_connect login [#{@target_url.user}]"
      @ftp.login @target_url.user, @target_url.password
    end

    def ftp_chdir_or_buildpath path
      # Method assertions
      info "Job.ftp_chdir [#{path}] mkdir: #{@mkdir}"
      raise RestFtpDaemon::JobAssertionFailed if path.nil?
      @status = :ftp_chdir

      # Extract directory from path
      if @mkdir
        # Split dir in parts
        info "Job.ftp_chdir buildpath [#{path}]"
        ftp_buildpath path
      else
        # Directly chdir if not mkdir requested
        info "Job.ftp_chdir chdir [#{path}]"
        @ftp.chdir path
      end
    end

    def ftp_buildpath path
      # Init
      pref = "Job.ftp_buildpath [#{path}]"

      begin
        # Try to chdir in this directory
        @ftp.chdir(path)

      rescue Net::FTPPermError => exception
        # If not possible because the directory is missing
        parent =  Helpers.extract_parent(path)
        info "#{pref} chdir failed - parent [#{parent}]"

        # And only if we still have something to "dive up into"
        if parent
          # Do the same for the parent
          ftp_buildpath parent

          # Then finally create this dir and chdir
          info "#{pref} > now mkdir [#{path}]"
          @ftp.mkdir path

          # And get into it (this chdir is not rescue'd on purpose in order to throw the ex)
          info "#{pref} > now chdir [#{path}]"
          @ftp.chdir(path)
        end

      end

      # Now we were able to chdir inside, just tell it
      info "#{pref} changed to [#{@ftp.pwd}]"
    end


    def ftp_presence target_name
# FIXME / TODO: try with nlst

      # Method assertions
      @status = :ftp_presence
      raise RestFtpDaemon::JobAssertionFailed if @ftp.nil? || @target_url.nil?

      # Get file list, sometimes the response can be an empty value
      results = @ftp.list(target_name) rescue nil
      info "Job.ftp_presence: #{results.inspect}"

      # Result can be nil or a list of files
      return false if results.nil?
      return results.count >0
    end

    def ftp_transfer source_match, target_name = nil
      # Method assertions
      info "Job.ftp_transfer source_match [#{source_match}]"
      raise RestFtpDaemon::JobAssertionFailed if @ftp.nil?
      raise RestFtpDaemon::JobAssertionFailed if source_match.nil?

      # Use source filename if target path provided none (typically with multiple sources)
      target_name ||= Helpers.extract_filename source_match
      info "Job.ftp_transfer target_name [#{target_name}]"
      set :source_processing, target_name

      # Check for target file presence
      @status = :checking_target
      present = ftp_presence target_name
      if present
        if @overwrite
          # delete it first
          info "Job.ftp_transfer removing target file"
          @ftp.delete(target_name)
        else
          # won't overwrite then stop here
          info "Job.ftp_transfer failed: target file exists"
          @ftp.close
          raise RestFtpDaemon::JobTargetFileExists
        end
      end

      # Read source file size and parameters
      update_every_kb = (Settings.transfer.update_every_kb rescue nil) || DEFAULT_UPDATE_EVERY_KB
      notify_after_sec = Settings.transfer.notify_after_sec rescue nil

      # Start transfer
      chunk_size = update_every_kb * 1024
      t0 = tstart = Time.now
      notified_at = Time.now
      @status = :uploading
      @ftp.putbinaryfile(source_match, target_name, chunk_size) do |block|
        # Update counters
        @transfer_sent += block.bytesize
        set :transfer_sent, @transfer_sent

        # Update bitrate
        #dt = Time.now - t0
        bitrate0 = get_bitrate(chunk_size, t0).round(0)
        set :transfer_bitrate, bitrate0

        # Update job info
        percent1 = (100.0 * @transfer_sent / @transfer_total).round(1)
        set :progress, percent1

        # Log progress
        stack = []
        stack << "#{percent1} %"
        stack << (Helpers.format_bytes @transfer_sent, "B")
        stack << (Helpers.format_bytes @transfer_total, "B")
        stack << (Helpers.format_bytes bitrate0, "bps")
        info "Job.ftp_transfer" + stack.map{|txt| ("%#{DEFAULT_LOGS_PROGNAME_TRIM.to_i}s" % txt)}.join("\t")

        # Update time pointer
        t0 = Time.now

        # Notify if requested
        unless notify_after_sec.nil? || (notified_at + notify_after_sec > Time.now)
          notif_status = {
            progress: percent1,
            transfer_sent: @transfer_sent,
            transfer_total: @transfer_total,
            transfer_bitrate: bitrate0
            }
          client_notify "rftpd.progress", nil, notif_status
          notified_at = Time.now
        end

      end

      # Compute final bitrate
      set :transfer_bitrate, get_bitrate(@transfer_total, tstart).round(0)

      # Done
      set :source_processing, nil
      info "Job.ftp_transfer finished"
      $queue.counter_inc :jobs_finished
    end

    def client_notify signal, error = nil, status = {}
      RestFtpDaemon::Notification.new @notify, {
        id: @id,
        signal: signal,
        error: error,
        status: status,
        }
    end

    def get_bitrate total, last_timestamp
      total.to_f / (Time.now - last_timestamp)
    end

  end
end
