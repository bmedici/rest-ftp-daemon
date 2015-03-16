require 'uri'
require 'net/ftp'
require 'double_bag_ftps'
require 'timeout'

module RestFtpDaemon
  class Job

    FIELDS = [:source, :target, :label, :priority, :notify, :overwrite, :mkdir, :tempfile]

    attr_accessor :wid

    attr_reader :id
    attr_reader :error
    attr_reader :status

    attr_reader :queued_at
    attr_reader :updated_at
    attr_reader :started_at
    attr_reader :finished_at

    attr_reader :params

    FIELDS.each do |name|
      attr_reader name
    end


    def initialize job_id, params={}
      # Call super
      # super()

      # Init context
      @id = job_id.to_s
      @params = {}
      @updated_at = nil
      @started_at = nil
      @finished_at = nil
      @error = nil
      @status = nil
      @wid = nil

      # Debug mode
      @ftp_debug_enabled = (Settings.at :debug, :ftp) == true

      # Logger
      @logger = RestFtpDaemon::LoggerPool.instance.get :workers

      # Protect with a mutex
      @mutex = Mutex.new

      # Import query params
      FIELDS.each do |name|
        instance_variable_set "@#{name.to_s}", params[name]
      end

      # Set super-default flags
      flag_default :mkdir, false
      flag_default :overwrite, false
      flag_default :tempfile, false

      # Flag current job
      @queued_at = Time.now

      # Send first notification
      info "Job.initialize notify: queued"
      client_notify :queued
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
        return oops :started, exception, :missing_attribute

      rescue RestFtpDaemon::JobUnresolvedTokens => exception
        return oops :started, exception, :unresolved_tokens

      rescue RestFtpDaemon::JobTargetUnparseable => exception
        return oops :started, exception, :target_unparseable

      rescue RestFtpDaemon::JobTargetUnsupported => exception
        return oops :started, exception, :target_unsupported

      rescue URI::InvalidURIError => exception
        return oops :started, exception, :target_invalid

      rescue RestFtpDaemon::JobAssertionFailed => exception
        return oops :started, exception, :assertion_failed

      rescue RestFtpDaemon::RestFtpDaemonException => exception
        return oops :started, exception, :prepare_failed, true

      rescue Exception => exception
        return oops :started, exception, :prepare_unhandled, true

      else
        # Prepare done !
        @status = :prepared
        info "Job.process notify: started"
        client_notify :started
      end

      # Process job
      begin
        info "Job.process transfer"
        @status = :starting
        transfer

      rescue SocketError => exception
        return oops :ended, exception, :conn_socket

      rescue EOFError => exception
        return oops :ended, exception, :conn_eof

      rescue Errno::EHOSTDOWN => exception
        return oops :ended, exception, :conn_host_is_down

      rescue Errno::ENOTCONN => exception
        return oops :ended, exception, :conn_failed

      rescue Errno::ECONNREFUSED => exception
        return oops :ended, exception, :conn_refused

      rescue Timeout::Error, Errno::ETIMEDOUT => exception
        return oops :ended, exception, :conn_timeout

      rescue OpenSSL::SSL::SSLError => exception
        return oops :ended, exception, :conn_openssl_error

      rescue Net::FTPPermError => exception
        return oops :ended, exception, :ftp_perm

      rescue Net::FTPTempError => exception
        return oops :ended, exception, :ftp_temp

      rescue Errno::EMFILE => exception
        return oops :ended, exception, :too_many_open_files

      rescue Errno::EINVAL => exception
        return oops :ended, exception, :invalid_argument, true

      rescue RestFtpDaemon::JobSourceNotFound => exception
        return oops :ended, exception, :source_not_found

      rescue RestFtpDaemon::JobTargetFileExists => exception
        return oops :ended, exception, :target_file_exists

      rescue RestFtpDaemon::JobTargetShouldBeDirectory => exception
        return oops :ended, exception, :target_not_directory

      rescue RestFtpDaemon::JobAssertionFailed => exception
        return oops :ended, exception, :assertion_failed

      rescue RestFtpDaemon::RestFtpDaemonException => exception
        return oops :ended, exception, :transfer_failed, true

      rescue Exception => exception
        return oops :ended, exception, :transfer_unhandled, true

      else
        # All done !
        @status = :finished
        info "Job.process notify: ended"
        client_notify :ended
      end

    end

    def get attribute
      @mutex.synchronize do
        @params || {}
        @params[attribute]
      end
    end

    def set_queued
      # Update job status
      @status = :queued
    end

    def oops_after_crash exception
      # info "Yes, we crash!"
      return oops :crashed, exception, :crashed
    end


  protected

    def age
      return nil if @queued_at.nil?
      (Time.now - @queued_at).round(2)
    end

    def exectime
      return nil if (@started_at.nil? || @finished_at.nil?)
      (@finished_at - @started_at).round(2)
    end

    def set attribute, value
      @mutex.synchronize do
        @params || {}
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
      vectors['RANDOM'] = SecureRandom.hex(JOB_RANDOM_LEN)

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
      # Update job status
      @status = :preparing

      # Init
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
      # Update job status
      @status = :checking_source
      @started_at = Time.now

      # Method assertions and init
      raise RestFtpDaemon::JobAssertionFailed, "transfer/1" unless @source_path
      raise RestFtpDaemon::JobAssertionFailed, "transfer/2" unless @target_url
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

      # Connect to remote server and login
      ftp_connect
      ftp_login

      # Change to the right path
      path = Helpers.extract_dirname(@target_url.path).to_s
      ftp_chdir_or_buildpath path

      # Check source files presence and compute total size, they should be there, coming from Dir.glob()
      @transfer_total = 0
      source_matches.each do |filename|
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

      # FTP transfer finished
      ftp_finish
    end


  private

    def flag_default name, default
      # build the flag instance var name
      variable = "@#{name.to_s}"

      # If it's true or false, that's ok
      return if [true, false].include? instance_variable_get(variable)

      # Otherwise, set it to the default value
      instance_variable_set variable, default
    end

    def ftp_init
      # Update job status
      @status = :ftp_init

      # Method assertions
      raise RestFtpDaemon::JobAssertionFailed, "ftp_init/1" if @target_method.nil?
      raise RestFtpDaemon::JobAssertionFailed, "ftp_init/2" if @target_url.nil?

      info "Job.ftp_init target_method [#{@target_method}]"
      case @target_method
      when :ftp
        @ftp = Net::FTP.new
      when :ftps
        @ftp = DoubleBagFTPS.new
        @ftp.ssl_context = DoubleBagFTPS.create_ssl_context(:verify_mode => OpenSSL::SSL::VERIFY_NONE)
        @ftp.ftps_mode = DoubleBagFTPS::EXPLICIT
      else
        info "Job.ftp_init unknown scheme [#{@target_url.scheme}]"
        railse RestFtpDaemon::JobTargetUnsupported
      end

      # FTP debug mode ?
      if @ftp_debug_enabled
        # Output header to STDOUT
        puts
        puts "-------------------- FTP SESSION STARTING --------------------"
        puts "job id\t #{@id}"
        puts "source\t #{@source}"
        puts "target\t #{@target}"
        puts "host\t #{@target_url.host}"
        puts "user\t #{@target_url.user}"
        puts "--------------------------------------------------------------"

        # Set debug mode on connection
        @ftp.debug_mode = true
      end

      # Activate passive mode
      @ftp.passive = true
    end

    def ftp_finish
      # Close FTP connexion
      @ftp.close
      info "Job.ftp_finish closed"

      # FTP debug mode ?
      if @ftp_debug_enabled
        puts "-------------------- FTP SESSION ENDED -----------------------"
      end

      # Update job status
      @status = :disconnecting
      @finished_at = Time.now

      # Update counters
      $queue.counter_inc :jobs_finished
      $queue.counter_add :transferred, @transfer_total
    end

    def ftp_connect
      # Update job status
      @status = :ftp_connect

      # Method assertions
      host = @target_url.host
      info "Job.ftp_connect [#{host}]"
      raise RestFtpDaemon::JobAssertionFailed, "ftp_connect/1" if @ftp.nil?
      raise RestFtpDaemon::JobAssertionFailed, "ftp_connect/2" if @target_url.nil?

      @ftp.connect(host)
    end

    def ftp_login
      # Update job status
      @status = :ftp_login

      # Method assertions
      raise RestFtpDaemon::JobAssertionFailed, "ftp_login/1" if @ftp.nil?

      # use "anonymous" if user is empty
      login = @target_url.user || "anonymous"
      info "Job.ftp_login [#{login}]"

      @ftp.login login, @target_url.password
    end

    def ftp_chdir_or_buildpath path
      # Method assertions
      info "Job.ftp_chdir [#{path}] mkdir: #{@mkdir}"
      @status = :ftp_chdir
      raise RestFtpDaemon::JobAssertionFailed, "ftp_chdir_or_buildpath/1" if path.nil?

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
      # Update job status
      @status = :ftp_presence
# FIXME / TODO: try with nlst

      # Method assertions
      raise RestFtpDaemon::JobAssertionFailed, "ftp_presence/1" if @ftp.nil?
      raise RestFtpDaemon::JobAssertionFailed, "ftp_presence/2" if @target_url.nil?

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
      raise RestFtpDaemon::JobAssertionFailed, "ftp_transfer/1" if @ftp.nil?
      raise RestFtpDaemon::JobAssertionFailed, "ftp_transfer/2" if source_match.nil?

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
          raise RestFtpDaemon::JobTargetFileExists
        end
      end

      # Read source file size and parameters
      update_every_kb = (Settings.transfer.update_every_kb rescue nil) || JOB_UPDATE_KB
      notify_after_sec = Settings.transfer.notify_after_sec rescue nil

      # Compute temp target name
      target_real = target_name
      if @tempfile
        target_real = "#{target_name}.#{Helpers.identifier(JOB_TEMPFILE_LEN)}-temp"
        info "Job.ftp_transfer target_real [#{target_real}]"
      end

      # Start transfer
      chunk_size = update_every_kb * 1024
      t0 = tstart = Time.now
      notified_at = Time.now
      @status = :uploading
      @ftp.putbinaryfile(source_match, target_real, chunk_size) do |block|
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
        info "Job.ftp_transfer" + stack.map{|txt| ("%#{DEFAULT_LOGS_PIPE_LEN.to_i}s" % txt)}.join("\t")

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
          client_notify :progress, status: notif_status
          notified_at = Time.now
        end

      end

      # Rename temp file to target_temp
      if @tempfile
        @status = :renaming
        info "Job.ftp_transfer renaming to #{target_name}"
        @ftp.rename target_real, target_name
      end

      # Compute final bitrate
      set :transfer_bitrate, get_bitrate(@transfer_total, tstart).round(0)

      # Done
      set :source_processing, nil
      info "Job.ftp_transfer finished"
    end

    def client_notify event, payload = {}
      # Skip if no URL given
      return unless @notify

      # Ok, create a notification!
      begin
        payload[:id] = @id
        payload[:event] = event
        RestFtpDaemon::Notification.new @notify, payload
      rescue Exception => ex
        info "Job.client_notify EXCEPTION: #{ex.inspect}"
      end
    end

    def get_bitrate total, last_timestamp
      total.to_f / (Time.now - last_timestamp)
    end


    def info message, context = {}
      return if @logger.nil?

      # Inject context
      context[:id] = @id
      context[:origin] = self.class

      # Forward to logger
      @logger.info_with_id message, context
    end

    def oops event, exception, error = nil, include_backtrace = false
      # Log this error
      error = exception.class if error.nil?

      message = "Job.oops event[#{event.to_s}] error[#{error.to_s}] ex[#{exception.class}] #{exception.message}"
      if include_backtrace
        info message, lines: exception.backtrace
      else
        info message
      end

      # Close ftp connexion if open
      @ftp.close unless @ftp.nil? || @ftp.welcome.nil?

      # Update job's internal status
      @status = :failed
      @error = error
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
      $queue.counter_inc "err_#{error}"
      $queue.counter_inc :jobs_failed

      # Prepare notification if signal given
      return unless event
      client_notify event, error: error, status: notif_status
    end

  end
end
