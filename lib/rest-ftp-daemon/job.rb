# FIXME: prepare files list ar prepare_common


# Reprensents work to be done along with parameters to process it
require "securerandom"

module RestFtpDaemon
  class Job
    include BmcDaemonLib::LoggerHelper
    include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
    include CommonHelpers

    # Class constants
    FIELDS = [:type, :source, :target, :label, :priority, :pool, :notify,
      :overwrite, :mkdir, :tempfile,
      :video_ac, :video_custom
    ]

    # Class options
    attr_reader :logger
    attr_accessor :wid
    attr_accessor :type

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
      @infos = {}

      # Store params
      # @params = params

      # Prepare configuration
      @config       = Conf[:transfer] || {}
      @endpoints    = Conf[:endpoints] || {}
      @pools        = Conf[:pools] || {}

      # Logger
      @logger = BmcDaemonLib::LoggerPool.instance.get :transfer

      # Protect with a mutex
      @mutex = Mutex.new

      # Import query params
      FIELDS.each do |name|
        instance_variable_set "@#{name}", params[name]
      end

      # Check if pool name exists
      if (@pools.keys.include? params[:pool])
        @pool = params[:pool].to_s
      else
        @pool = DEFAULT_POOL
      end

      # Prepare sources/target
      prepare_source
      prepare_target

      # Store options
      # @options = params[:options].to_hash
      # log_info "Job.initialize params[:options]: #{params[:options].inspect}"
      # log_info "Job.initialize params[:options][:opt1]: #{params[:options][:opt1]}"


    end

    def reset
      # Update job status
      set_status JOB_STATUS_PREPARING

      # Flag current job timestamps
      @queued_at = Time.now
      @updated_at = Time.now

      # Job has been prepared, reset infos
      set_status JOB_STATUS_PREPARED
      @infos = {}
      set_info :job, :prepared_at, Time.now
      set_info_location :source, @source_loc
      set_info_location :target, @target_loc

      # Update job status, send first notification
      set_status JOB_STATUS_QUEUED
      set_error nil
      client_notify :queued
      log_info "Job.reset notify[queued]"
    end

    def process
      # Check prerequisites
      raise RestFtpDaemon::AssertionFailed, "run/source_loc" unless @source_loc
      raise RestFtpDaemon::AssertionFailed, "run/target_loc" unless @target_loc

    #   # Prepare
    #   begin
    #     log_info "Job.process: raise a fake error"
    #     raise RestFtpDaemon::PrepareError, "fake_error_common"
    #     # prepare

    #   rescue PrepareError => ex
    #     log_info "Job.process: rescue a fake error: #{ex.inspect}"
    #     # return oops :started, PrepareError, ex.message

    #   else
    #     log_info "Job.process: no exception caught"
    #   end

    #   # # Prepare done !
    #   # set_status JOB_STATUS_PREPARED
    #   # log_info "Job.process notify [started]"
    #   # client_notify :started

    #   # # Run
    #   # run

    #   # # Run done !
    #   # set_status JOB_STATUS_FINISHED
    #   # log_info "Job.process notify [ended]"
    #   # client_notify :ended
    # end

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

    def alert_common_method_called
      log_error "Job PLACEHOLDER METHOD CALLED"
    end

    def prepare_common
      # Init
      @source_path = nil
    def prepare_source
      raise RestFtpDaemon::AttributeMissing, "source" unless @source
      @source_loc = Location.new @source
      log_info "Job.prepare_source #{@source_loc.uri}"
    end

    def prepare_target
      raise RestFtpDaemon::AttributeMissing, "target" unless @target
      @target_loc = Location.new @target
      log_info "Job.prepare_target #{@target_loc.uri}"
    end

    def set_info_location prefix, location
      return unless location.is_a? Location
      set_info prefix, :location_uri,    location.to_s
      set_info prefix, :location_scheme, location.scheme
      set_info prefix, :location_path,   location.path
      set_info prefix, :location_host,   location.host
    end

      # Update job status
      set_status JOB_STATUS_PREPARING
      @runs += 1



      log_info "Job.prepare target_path path[#{@target_path}] scheme[#{@target_uri.scheme}]"
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


    def contains_brackets item
      /\[.*\]/.match(item)
    end

    def replace_tokens path
      end

      # Ensure result does not contain tokens after replacement
      raise RestFtpDaemon::JobUnresolvedTokens if contains_brackets newpath

      # All OK, return this URL stripping multiple slashes
      newpath.gsub(/([^:])\/\//, '\1/')
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
      end
      touch_job
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
      RestFtpDaemon::Counters.instance.increment :errors, error
      RestFtpDaemon::Counters.instance.increment :jobs, :failed

      # Prepare notification if signal given
      return unless event
      client_notify event, error: error, status: notif_status, message: "#{exception.class} | #{exception.message}"
    end

    # NewRelic instrumentation
    add_transaction_tracer :client_notify,  category: :task
    add_transaction_tracer :initialize,     category: :task

  end
end
