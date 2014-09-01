module RestFtpDaemon
  class Job

    def initialize(id, params={})
      # Grab params
      @params = params
      @target = nil
      @source = nil

      # Init context
      set :id, id
      set :started_at, Time.now
      set :status, :initialized

      # Send first notification
      notify "rftpd.queued"
    end

    def id
      @params[:id]
    end

    def process
      # Init
      "process [#{@id}] starting"
      set :status, :starting
      set :error, 0

      begin
        # Validate job and params
        prepare

        # Process
        transfer

      rescue Net::FTPPermError
        set :status, :failed
        set :error, exception.class

      rescue RestFtpDaemonException => exception
        set :status, :failed
        set :error, exception.class

      # rescue Exception => exception
      #   set :status, :crashed
      #   set :error, exception.class

      else
        set :status, :finished
        set :error, 0
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

    def wander time
      @wander_for = time
      @wander_started = Time.now
      sleep time
    end

    def status text
      @status = text
    end

  protected

    def up_time
      return if @params[:started_at].nil?
      Time.now - @params[:started_at]
    end

    def wandering_time
      return if @wander_started.nil? || @wander_for.nil?
      @wander_for.to_f - (Time.now - @wander_started)
    end

    def exception_handler(actor, reason)
      set :status, :crashed
      set :error, reason
    end

    def set attribute, value
      return unless @params.is_a? Enumerable
      @params[:updated_at] = Time.now
      @params[attribute.to_s] = value
    end

    def get attribute
      return unless @params.is_a? Enumerable
      @params[attribute.to_s]
    end

    def prepare
      # Init
      set :status, :preparing

      # Check source
      raise JobSourceMissing unless @params["source"]
      @source = File.expand_path(@params["source"])
      set :debug_source, @source
      raise JobSourceNotFound unless File.exists? @source

      # Check target
      raise JobTargetMissing unless @params["target"]
      @target = URI(@params["target"]) rescue nil
      set :debug_target, @target.inspect
      raise JobTargetUnparseable if @target.nil?
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
      transferred = 0
      notify "rftpd.started"

      # Ensure @source and @target are there
      set :status, :checking_source
      raise JobPrerequisitesNotMet unless @source
      raise JobPrerequisitesNotMet unless @source
      target_path = File.dirname @target.path
      target_name = File.basename @target.path

      # Read source file size
      source_size = File.size @source
      set :file_size, source_size

      # Prepare FTP transfer
      set :status, :checking_target
      ftp = Net::FTP.new(@target.host)
      ftp.passive = true
      ftp.login
      ftp.chdir(target_path)

      # Check for target file presence
      results = ftp.list(target_name)

      #info "ftp.list: #{results}"
      unless results.count.zero?
        ftp.close
        raise JobTargetPermission
      end

      # Do transfer
      set :status, :uploading
      ftp.putbinaryfile(@source, target_name, TRANSFER_CHUNK_SIZE) do |block|
        # Update counters
        transferred += block.bytesize

        # Update job info
        percent = (100.0 * transferred / source_size).round(1)
        set :file_progress, percent
        set :file_sent, transferred
      end

      # Close FTP connexion
      notify "rftpd.ended"
      ftp.close
    end

  protected

    def notify signal, status = {}
      puts "RestFtpDaemon::Job.notify [#{get :notify}] [#{signal}] #{status.inspect}"

      # Skip is not callback URL defined
      url = get :notify
      if url.nil?
        puts "RestFtpDaemon::Job.notify [#{get :notify}] [#{signal}] skipping"
        return
      end

      # Prepare notif body
      n = RestFtpDaemon::Notification.new
      n.id = get(:id)
      n.url = url
      n.signal = signal
      #n.status ={dummy: true}

      # Now, send the notification
      Thread.new(n) do |thread|
        n.notify!
        puts "RestFtpDaemon::Job.notify [#{get :notify}] [#{signal}] sent"
      end

    end

  end
end
