# FIXME: prepare files list ar prepare_common
# FIXME: scope classes in submodules like Worker::Transfer, Job::Video
# FIXME: restore HostKeyMismatch and other NEt::SFTP exceptions

# Represents work to be done along with parameters to process it
require "securerandom"

module RestFtpDaemon
  class Job
    include BmcDaemonLib::LoggerHelper
    include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
    include CommonHelpers

    # Statuses
    STATUS_QUEUED    = "queued"
    STATUS_FAILED    = "failed"

    STATUS_PREPARING = "preparing"
    STATUS_PREPARED  = "prepared"
    STATUS_FINISHED  = "finished"

    STATUS_IMPORT_LISTING       = "import/list"

    STATUS_VIDEO_TRANSFORMING   = "video/transform"

    STATUS_EXPORT_CONNECTING    = "export/connect"
    STATUS_EXPORT_CHDIR         = "export/chdir"
    STATUS_EXPORT_UPLOADING     = "export/upload"
    STATUS_EXPORT_RENAMING      = "export/rename"
    STATUS_EXPORT_DISCONNECTING = "export/disconnect"


    # Types
    TYPE_TRANSFER    = "transfer"
    TYPE_VIDEO       = "video"
    TYPE_WORKFLOW    = "workflow"
    TYPE_DUMMY       = "dummy"
    TYPES            = [TYPE_TRANSFER, TYPE_VIDEO, TYPE_WORKFLOW, TYPE_DUMMY]

    # Other constats
    DEFAULT_POOL     = "default"



    # Logging

    # Fields to be imported from params
    IMPORTED = %w(type priority pool label priority source target options overwrite notify mkdir tempfile video_options video_custom)

    # Class options
    attr_accessor :wid
    attr_reader :id

    attr_reader :source_loc
    attr_reader :target_loc

    attr_reader :infos
    attr_reader :error
    attr_reader :status
    attr_reader :tentatives
    attr_reader :options

    attr_reader :created_at
    attr_reader :updated_at
    attr_reader :started_at
    attr_reader :finished_at

    attr_reader :created_since
    attr_reader :started_since
    attr_reader :finished_in

    # Workflow-specific
    attr_accessor :current
    attr_reader :tasks

    # Define readers from imported fields
    IMPORTED.each do |field|
      attr_reader field
    end

    def initialize job_id = nil, params = {}
      # Minimal init
      @infos = {}
      @mutex = Mutex.new

      # Skip if no job_id passed or null (mock Job)
      return if job_id.nil?

      # Init context
      @id           = job_id.to_s
      @updated_at   = nil
      @error        = nil
      @status       = nil
      @tentatives   = 0
      @wid          = nil
      @created_at   = Time.now

      # Init: worfklow-specific
      @tasks        = []
      @current      = []

      # Logger # FIXME: should be :jobs
      log_pipe      :transfer

      # Prepare configuration
      @config       = Conf[:transfer] || {}
      @endpoints    = Conf[:endpoints] || {}

      # Import query params
      set_info INFO_PARAMS, params
      IMPORTED.each do |field|
        instance_variable_set "@#{field}", params[field]
      end

      # Ensure @options is a hash
      @options = {} unless @options.is_a? Hash

      # Adjust params according to defaults
      job_flag_init :transfer, :overwrite
      job_flag_init :transfer, :mkdir
      job_flag_init :transfer, :tempfile

      # Check if pool name exists
      Conf[:pools] ||= {}
      @pool = DEFAULT_POOL unless Conf[:pools].keys.include?(@pool)

      # Prepare sources/target
      raise RestFtpDaemon::JobAttributeMissing, "source" unless params[:source]
      @source_loc = Location.new(params[:source])

      raise RestFtpDaemon::JobAttributeMissing, "target" unless params[:target]
      @target_loc = Location.new(params[:target])

      # We're done!
      log_info "initialized", {
        source: @source_loc.uri,
        target: @target_loc.uri,
        pool: @pool,
        }
    end

    def reset
      # Update job status
      set_status STATUS_PREPARING

      # Increment run cours
      @tentatives +=1
      @updated_at = Time.now
      @started_at   = nil
      @finished_at  = nil

      # Job has been prepared, reset infos
      set_status STATUS_PREPARED
      @infos = {}

      # Update job status, send first notification
      set_status STATUS_QUEUED
      set_error nil
      job_notify :queued
      log_info "reset notify[queued] tentative[#{@tentatives}]"
    end

    # Process job
    def start
      # Check prerequisites
      raise RestFtpDaemon::AssertionFailed, "run/source_loc" unless @source_loc
      raise RestFtpDaemon::AssertionFailed, "run/target_loc" unless @target_loc

      # Remember when we started
      @started_at = Time.now

      # Notify we start working
      log_info "job_notify [started]"
      current_signal = :started
      set_status Worker::STATUS_WORKING
      job_notify :started

      # Before work
      log_debug "do_before"
      current_signal = :started
      do_before

      # Do the hard work
      log_debug "do_work"
      current_signal = :ended
      do_work

      # Finalize all this
      log_debug "do_after"
      current_signal = :ended
      do_after

    rescue StandardError => exception
      Rollbar.error exception, "job [#{error}]: #{exception.class.name}: #{exception.message}"
      return oops current_signal, exception

    else
      # All done !
      set_status STATUS_FINISHED
      log_info "job_notify [ended]"
      job_notify :ended
    end

    # Process job if it's a workflow
    def start_workflow
      log_info "start_workflow"

      # Register tasks
      register_task :import,    TaskImport
      register_task :transform, TaskTransform
      register_task :export,    TaskExport

      # Run tasks
      @tasks.each do |task|
        log_info "task: #{task.name}"
        
        # Prepare, run and finish task
        task.do_before
        task.do_work
        task.do_after

        #FIXME
        sleep JOB_DELAY_TASKS

        # Finish
        task.error = 0
        # task.do_finalize
       end
    end


    def before
    end
    def work
    end
    def after
    end

    def source_uri
      @source_loc.uri if @source_loc
    end

    def target_uri
      @target_loc.uri if @target_loc
    end

    def weight
      @weight = [
        - @tentatives.to_i,
        + @priority.to_i,
        - @created_at.to_i,
        ]
    end

    def started_since
      since @started_at
    end

    def created_since
      since @created_at
    end

    def finished_in
      return nil if @started_at.nil? || @finished_at.nil?
      (@finished_at - @started_at).round(2)
    end

    def oops_end what, exception
      Rollbar.error exception, "oops_end [#{what}]: #{exception.class.name}: #{exception.message}"
      oops :ended, exception, what
    end

    def targethost
      @target_loc.host unless @target_loc.nil?
      #get_info :target_host
    end

     def get_info name
    def get_option scope, name
      @options[scope] ||= {}
      @options[scope][name]
    end
    
    def set_option scope, name, value
      @options[scope] ||= {}
      @options[scope][name] = value
    end

      @mutex.synchronize do
        @infos[name]
      end
    end

    def set_info name, value
      @mutex.synchronize do
        @infos || {}
        @infos[name] = debug_value_utf8(value)
      end
      job_touch
    end

    def set_status value
      @mutex.synchronize do
        @status = value
      end
      touch_job
    end

  protected

    def alert_common_method_called
      log_error "PLACEHOLDER METHOD CALLED"
    end

  private

    def log_context
      {
      wid: @wid,
      jid: @id,
      #id: @id,
      }
    end

    def job_touch
      now = Time.now
      @updated_at = now
      Thread.current.thread_variable_set :updated_at, now
    end

    # Timestamps calculation
    def since timestamp
      return nil if timestamp.nil?
      return (Time.now - timestamp).round(2)
    end

    # Force strings to UTF8
    def debug_value_utf8 value
      case value
      when Symbol
        return value.to_s.force_encoding(Encoding::UTF_8)
      when String
        return value.dup.force_encoding(Encoding::UTF_8) if value.is_a? String
      else
        return value
      end
    end

    def set_error value
      @mutex.synchronize do
        @error = value
      end
      job_touch
    end

    def set_status value
      @mutex.synchronize do
        @status = value
      end
      touch_job
    end

    # def job_status value
    #   set_status value
    # end  

    def job_flag_init scope, name
      # build the flag instance var name
      variable = "@#{name}"

      # If it's already true or false, that's ok
      return if [true, false].include? get_option(scope, name)

      # Otherwise, set it to the new alt_value
      set_option(scope, name, Conf.at(scope, name))
      # instance_variable_set variable, 
    end

    def job_notify signal, payload = {}
      # Skip if no URL given
      return unless @notify

      # Ok, create a notification!
      payload[:id] = @id
      payload[:signal] = signal
      RestFtpDaemon::Notification.new @notify, payload

    rescue StandardError => ex
      log_error "job_notify EXCEPTION: #{ex.inspect}"
    end

    def oops signal, exception, error = nil#, include_backtrace = false
      # Find error code in ERRORS table
      if error.nil?
        error = ERRORS.key(exception.class)
      end

      # Default error code derived from exception name
      if error.nil?
        error = exception_to_error(exception)
        include_backtrace = true
      end

      # Log message and backtrace ?
      log_error "OOPS: #{exception.class}", {
        exception: exception.class.to_s,
        message: exception.message,
        error: error,
        signal: signal,
        }  
      log_debug "OOPS: backtrace below", exception.backtrace if include_backtrace
  
      # Log to Rollbar
      Rollbar.warning exception, "oops [#{error}]: #{exception.class.name}: #{exception.message}"

      # Close ftp connexion if open
      @remote.close unless @remote.nil? || !@remote.connected?

      # Update job's internal status
      set_status STATUS_FAILED
      set_error error
      set_info INFO_ERROR_EXCEPTION, exception.class.to_s
      set_info INFO_ERROR_MESSAGE,   exception.message

      # Build status stack
      notif_status = nil
      if include_backtrace
        set_info INFO_ERROR_BACKTRACE, exception.backtrace
        notif_status = {
          backtrace: exception.backtrace,
          }
      end

      # Increment counter for this error
      RestFtpDaemon::Counters.instance.increment :errors, error
      RestFtpDaemon::Counters.instance.increment :jobs, :failed

      # Prepare notification if signal given
      return unless signal
      job_notify signal, error: error, status: notif_status, message: "#{exception.class} | #{exception.message}"
    end

    # NewRelic instrumentation
    add_transaction_tracer :job_notify,  category: :task
    add_transaction_tracer :initialize,     category: :task

  end
end
