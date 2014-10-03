#require 'net/ftptls'

require 'uri'
require 'net/ftp'
require 'double_bag_ftps'

module RestFtpDaemon
  class Job < RestFtpDaemon::Common

    def initialize(id, params={})
      # Call super
      super()

      # Grab params
      @params = params
      @target = nil
      @source = nil

      # Init context
      set :id, id
      set :started_at, Time.now
      set :status, :created

      # Send first notification
      notify "rftpd.queued"
    end

    def progname
      job_id = get(:id)
      "JOB #{job_id}"
    end

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
      # Init
      info "Job.process starting"
      set :status, :starting
      set :error, 0

      begin
        # Validate job and params
        prepare

        # Process
        transfer

      rescue Net::FTPPermError => exception
        info "Job.process failed [Net::FTPPermError]"
        set :status, :failed
        set :error, exception.class

      rescue RestFtpDaemonException => exception
        info "Job.process failed [::#{exception.class}]"
        set :status, :failed
        set :error, exception.class

      rescue Exception => exception
        info "Job.process exception [#{exception.class}] #{exception.backtrace.inspect}"
        set :status, :crashed
        set :error, exception.class

      else
        info "Job.process finished"
        set :status, :finished
      end

    end

    def describe
      # Update realtime info
      w = wandering_time
      set :wandering, w.round(2) unless w.nil?

      # Update realtime info
      u = up_time
      set :uptime, u.round(2) unless u.nil?

      # Return the whole structure
      @params
    end

    def status text
      @status = text
    end

    def get attribute
      return nil unless @params.is_a? Enumerable
      @params[attribute.to_s]
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

    # def exception_handler(actor, reason)
    #   set :status, :crashed
    #   set :error, reason
    # end

    def set attribute, value
      return unless @params.is_a? Enumerable
      @params[:updated_at] = Time.now
      @params[attribute.to_s] = value
    end

    def expand_path_from path
      File.expand_path replace_token_in_path(path)
    end

    def expand_url_from path
      URI::parse replace_token_in_path(path) rescue nil
    end

    def replace_token_in_path path
      # Ensure endpoints are not a nil value
      return path unless Settings.endpoints.is_a? Enumerable
      newpath = path.clone

      # Replace endpoints defined in config
      Settings.endpoints.each do |from, to|
        newpath.gsub! "[#{from}]", to
      end

      # Replace with the special RAND token
      newpath.gsub! "[RANDOM]", SecureRandom.hex(8)

      return newpath
    end

    def prepare
      # Init
      info "Job.prepare"
      set :status, :preparing

      # Check source
      raise JobSourceMissing unless @params["source"]
      @source = expand_path_from @params["source"]
      set :debug_source, @source

      # Check target
      raise JobTargetMissing unless @params["target"]
      @target = expand_url_from @params["target"]
      set :debug_target_expanded, expand_url_from(@params["target"])
      set :debug_target, @target.inspect

      # Check protocols
      raise JobTargetUnsupported unless @target.kind_of?(URI::FTP) || @target.kind_of?(URI::FTPS)

      # Check compliance
      raise JobTargetUnparseable if @target.nil?
      raise JobSourceNotFound unless File.exists? @source

    end

    def transfer_fake
      # Init
      set :status, :faking

      # Work
      (0..9).each do |i|
        set :faking, i
        sleep 0.5
      end
    end

    def transfer
      # Init
      info "Job.transfer"

      # Send first notification
      transferred = 0
      notify "rftpd.started"

      # Ensure @source and @target are there
      info "Job.transfer checking_source"
      set :status, :checking_source
      raise RestFtpDaemon::JobPrerequisitesNotMet unless @source
      raise RestFtpDaemon::JobPrerequisitesNotMet unless @target
      target_path = File.dirname @target.path
      target_name = File.basename @target.path

      # Read source file size
      source_size = File.size @source
      set :file_size, source_size

      # Prepare FTP transfer
      info "Job.transfer preparing"

      # Scheme-aware config
      if @target.kind_of? URI::FTP
        info "Job.transfer scheme FTP"
        ftp = Net::FTP.new
      elsif @target.kind_of? URI::FTPS
        info "Job.transfer scheme FTPS"
        ftp = DoubleBagFTPS.new
        ftp.ssl_context = DoubleBagFTPS.create_ssl_context(:verify_mode => OpenSSL::SSL::VERIFY_NONE)
        ftp.ftps_mode = DoubleBagFTPS::EXPLICIT
      else
        info "Job.transfer scheme other: [#{@target.scheme}]"
      end

      # Connect remote server
      info "Job.transfer connecting"
      set :status, :connecting
      ftp.connect(@target.host)
      ftp.passive = false

      # Logging in
      info "Job.transfer login"
      begin
        u = ftp.login @target.user, @target.password
      rescue Exception => exception
        info "Job.process login failed [#{exception.class}] #{u.inspect}"
        set :status, :login_failed
        set :error, exception.class
      end

      # Changing to directory
      info "Job.transfer chdir"
      set :status, :chdir
      ftp.chdir(target_path)

      # Check for target file presence
      if get(:overwrite).nil?
        info "Job.transfer remote_check (#{target_name})"
        set :status, :remote_check

        # Get file list, sometimes the response can be an empty value
        results = ftp.list(target_name) rescue nil

        # Result can be nil or a list of files
        if results.nil? || results.count.zero?
          info "Job.transfer remote_absent"
          set :status, :remote_absent
        else
          info "Job.transfer remote_present"
          set :status, :remote_present
          ftp.close
          notify "rftpd.ended", RestFtpDaemon::JobTargetFileExists
          raise RestFtpDaemon::JobTargetFileExists
        end

      end

      # Do transfer
      info "Job.transfer uploading"
      set :status, :uploading
      chunk_size = Settings.transfer.chunk_size || Settings[:app_chunk_size]
      ftp.putbinaryfile(@source, target_name, chunk_size) do |block|
        # Update counters
        transferred += block.bytesize

        # Update job info
        percent = (100.0 * transferred / source_size).round(1)
        set :progress, percent
        set :file_sent, transferred
      end

      # Close FTP connexion
      info "Job.transfer closing"
      set :status, :disconnecting
      notify "rftpd.ended"
      set :progress, nil
      ftp.close
    end

  private

  end
end
