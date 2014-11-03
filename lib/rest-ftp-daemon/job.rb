#require 'net/ftptls'

require 'uri'
require 'net/ftp'
require 'double_bag_ftps'
require 'timeout'

module RestFtpDaemon
  class Job < RestFtpDaemon::Common
    attr_accessor :wid

    def initialize(id, params={})
      # Call super
      # super()
      info "Job.initialize"

      # Generate new Job.id
      # $queue.counter_add :transferred, source_size

      # Logger
      @logger = RestFtpDaemon::Logger.new(:workers, "JOB #{id}")

      # Protect with a mutex
      @mutex = Mutex.new

      # Init context
      @params = params
      set :id, id
      set :started_at, Time.now
      status :created

      # Send first notification
      info "Job.initialize/notify"
      notify "rftpd.queued"
    end

    # def progname
    #   job_id = get(:id)
    #   "JOB #{job_id}"
    # end

    def id
      get :id
    end

    def priority
      get :priority
    end
    def get_status
      get :status
    end

    def process
      # Update job's status
      set :error, nil

      # Prepare job
      begin
        info "Job.process/prepare"
        status :preparing
        prepare

      rescue RestFtpDaemon::JobMissingAttribute => exception
        return oops "rftpd.started", exception, :job_missing_attribute

      rescue RestFtpDaemon::JobSourceNotFound => exception
        return oops "rftpd.started", exception, :job_source_not_found

      rescue RestFtpDaemon::RestFtpDaemonException => exception
        return oops "rftpd.started", exception, :job_prepare_failed

      rescue Exception => exception
        return oops "rftpd.started", exception, :job_prepare_unhandled, true

      rescue exception
        return oops "rftpd.started", exception, :WOUHOU, true

      else
        # Update job's status
        info "Job.process/prepare ok"
        status :prepared
        info "Job.process/prepare status updated"

        # Notify rftpd.start
        info "Job.process/prepare notify started"
        notify "rftpd.started", 0
        info "Job.process/prepare notified started"
      end

      info "Job.process prepare>transfer"

      # Process job
      begin
        info "Job.process/transfer"
        status :starting
        transfer

      rescue Timeout::Error => exception
        return oops "rftpd.ended", exception, :job_timeout_error

      rescue Net::FTPPermError => exception
        return oops "rftpd.ended", exception, :job_ftp_perm_error

      rescue Errno::ECONNREFUSED => exception
        return oops "rftpd.ended", exception, :job_connexion_refused

      rescue Errno::EMFILE => exception
        return oops "rftpd.ended", exception, :job_too_many_open_files

      rescue RestFtpDaemon::JobTargetFileExists => exception
        return oops "rftpd.ended", exception, :job_target_file_exists

      rescue RestFtpDaemon::RestFtpDaemonException => exception
        return oops "rftpd.ended", exception, :job_transfer_failed

      rescue Exception => exception
        return oops "rftpd.ended", exception, :job_transfer_unhandled, true

      else
        # Update job's status
        info "Job.process finished"
        status :finished

        # Notify rftpd.ended
        notify "rftpd.ended", 0
      end

    end

    def describe
      # Update realtime info
      u = up_time
      set :uptime, u.round(2) unless u.nil?

      # Return the whole structure  FIXME
      @params
      # @mutex.synchronize do
      #   out = @params.clone
      # end
    end

    def get attribute
      @mutex.synchronize do
        @params || {}
        @params[attribute]
      end
    end

  protected

    def up_time
      return if @params[:started_at].nil?
      Time.now - @params[:started_at]
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
        @params[:updated_at] = Time.now
        @params[attribute] = value
      end
    end

    def status status
      set :status, status
    end

    def expand_path path
      File.expand_path replace_token(path)
    end

    def expand_url path
      URI::parse replace_token(path) rescue nil
    end

    def replace_token path
      # Ensure endpoints are not a nil value
      return path unless Settings.endpoints.is_a? Enumerable
      vectors = Settings.endpoints.clone

      # Stack RANDOM into tokens
      vectors['RANDOM'] = SecureRandom.hex(IDENT_RANDOM_LEN)

      # Replace endpoints defined in config
      newpath = path.clone
      vectors.each do |from, to|
        next if to.to_s.blank?
        #info "Job.replace_token #{Helpers.tokenize(from)} > #{to}"
        newpath.gsub! Helpers.tokenize(from), to
      end

      return newpath
    end

    def prepare
      # Init
      status :preparing
      @source_method = :file
      @target_method = nil
      @source_path = nil
      @target_url = nil

      # Check source
      raise RestFtpDaemon::JobMissingAttribute unless @params[:source]
      @source_path = expand_path @params[:source]
      set :source_path, @source_path
      set :source_method, :file

      # Check target
      raise RestFtpDaemon::JobMissingAttribute unless @params[:target]
      @target_url = expand_url @params[:target]
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
      raise RestFtpDaemon::JobSourceNotFound unless File.exists? @source_path
    end

    def transfer
      # Method assertions
      info "Job.transfer checking_source"
      status :checking_source
      raise RestFtpDaemon::JobAssertionFailed unless @source_path &&  @target_url

      # Init

      target_name = File.basename @target_url.path

      # Scheme-aware config
      ftp_init

      # Connect remote server, login and chdir
      ftp_connect

      # Check for target file presence
      if get(:overwrite).nil? && (ftp_presence target_name)
        @ftp.close
        raise RestFtpDaemon::JobTargetFileExists
      end

      # Do transfer
      ftp_transfer target_name

      # Close FTP connexion
      info "Job.transfer disconnecting"
      status :disconnecting
      @ftp.close
    end

  private

    def oops signal_name, exception, error_name = nil, include_backtrace = false
      # Log this error
      error_name = exception.class if error_name.nil?
      info "Job.oops si[#{signal_name}] er[#{error_name.to_s}] ex[#{exception.class}]"

      # Update job's internal status
      set :status, :failed
      set :error, error_name
      set :error_exception, exception.class

      # Build status stack
      status = nil
      if include_backtrace
        set :error_backtrace, exception.backtrace
        status = {
          backtrace: exception.backtrace,
        }
      end

      # Prepare notification if signal given
      return unless signal_name
      notify signal_name, error_name, status
    end

    def ftp_init
      # Method assertions
      info "Job.ftp_init"
      status :ftp_init
      raise RestFtpDaemon::JobAssertionFailed if @target_method.nil? || @target_url.nil?

      case @target_method
      when :ftp
        info "Job.ftp_init scheme: ftp"
        @ftp = Net::FTP.new
      when :ftps
        info "Job.transfer scheme: ftps"
        @ftp = DoubleBagFTPS.new
        @ftp.ssl_context = DoubleBagFTPS.create_ssl_context(:verify_mode => OpenSSL::SSL::VERIFY_NONE)
        @ftp.ftps_mode = DoubleBagFTPS::EXPLICIT
      else
        info "Job.transfer scheme: other [#{@target_url.scheme}]"
      end
    end

    def ftp_connect
      #status :ftp_connect
      # connect_timeout_sec = (Settings.transfer.connect_timeout_sec rescue nil) || DEFAULT_CONNECT_TIMEOUT_SEC

      # Method assertions
      info "Job.ftp_connect connect"
      status :ftp_connect
      raise RestFtpDaemon::JobAssertionFailed if @ftp.nil? || @target_url.nil?

        ret = @ftp.connect(@target_url.host)
        @ftp.passive = true

      info "Job.ftp_connect login"
      status :ftp_login
      ret = @ftp.login @target_url.user, @target_url.password

      info "Job.ftp_connect chdir"
      status :ftp_chdir
      path = File.dirname @target_url.path
      ret = @ftp.chdir(path)
    end

    def ftp_presence target_name
      # Method assertions
      info "Job.ftp_presence"
      status :ftp_presence
      raise RestFtpDaemon::JobAssertionFailed if @ftp.nil? || @target_url.nil?

      # Get file list, sometimes the response can be an empty value
      results = @ftp.list(target_name) rescue nil

      # Result can be nil or a list of files
      return false if results.nil?
      return results.count >0
    end

    def ftp_transfer target_name
      # Method assertions
      info "Job.ftp_transfer starting"
      status :ftp_transfer
      raise RestFtpDaemon::JobAssertionFailed if @ftp.nil? || @source_path.nil?

      # Read source file size and parameters
      source_size = File.size @source_path
      set :transfer_size, source_size
      update_every_kb = (Settings.transfer.update_every_kb rescue nil) || DEFAULT_UPDATE_EVERY_KB
      notify_after_sec = Settings.transfer.notify_after_sec rescue nil

      # Start transfer
      transferred = 0
      chunk_size = update_every_kb * 1024
      t0 = tstart = Time.now
      notified_at = Time.now
      status :uploading
      @ftp.putbinaryfile(@source_path, target_name, chunk_size) do |block|
        # Update counters
        transferred += block.bytesize
        set :transfer_sent, transferred

        # Update bitrate
        dt = Time.now - t0
        bitrate0 = (8 * chunk_size/dt).round(0)
        set :transfer_bitrate, bitrate0

        # Update job info
        percent1 = (100.0 * transferred / source_size).round(1)
        set :progress, percent1

        # Log progress
        status = []
        status << "#{percent1} %"
        status << (Helpers.format_bytes transferred, "B")
        status << (Helpers.format_bytes source_size, "B")
        status << (Helpers.format_bytes bitrate0, "bps")
        info "Job.ftp_transfer" + status.map{|txt| ("%#{DEFAULT_LOGS_PROGNAME_TRIM.to_i}s" % txt)}.join("\t")

        # Update time pointer
        t0 = Time.now

        # Notify if requested
        unless notify_after_sec.nil? || (notified_at + notify_after_sec > Time.now)
          status = {
            progress: percent1,
            transfer_sent: transferred,
            transfer_size: source_size,
            transfer_bitrate: bitrate0
            }
          notify "rftpd.progress", 0, status
          notified_at = Time.now
        end

      end

      # Compute final bitrate
      tbitrate0 = (8 * source_size.to_f / (Time.now - tstart)).round(0)
      set :transfer_bitrate, tbitrate0

      # Add total transferred to counter
      $queue.counter_add :transferred, source_size

      # Done
      #set :progress, nil
      info "Job.ftp_transfer finished"
    end

    def notify signal, error = 0, status = {}
      RestFtpDaemon::Notification.new get(:notify), {
        id: get(:id),
        signal: signal,
        error: error,
        status: status,
        }
    end

  end
end
