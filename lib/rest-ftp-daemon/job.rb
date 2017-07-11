# FIXME: prepare files list ar prepare_common
# FIXME: scope classes in submodules like Worker::Transfer, Job::Video
# FIXME: restore HostKeyMismatch and other NEt::SFTP exceptions
# FIXME: move progress from Job/infos/transfer to Job/progress

# Represents work to be done along with parameters to process it
require "securerandom"

module RestFtpDaemon
  class JobNotFound               < BaseException; end

  class JobTimeout                < BaseException; end
  class JobUnknownTransform       < BaseException; end
  class JobNotFound               < BaseException; end
  class JobAttributeMissing       < BaseException; end
  class JobUnresolvedTokens       < BaseException; end


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

    STATUS_TASK_PROCESSING   = "video/transform"


    # Types
    TYPE_TRANSFER    = "transfer"
    TYPE_VIDEO       = "video"
    TYPE_WORKFLOW    = "workflow"
    TYPE_DUMMY       = "dummy"
    TYPES            = [TYPE_TRANSFER, TYPE_VIDEO, TYPE_WORKFLOW, TYPE_DUMMY]

    # Other constats
    DEFAULT_POOL     = "default"

    # PROCESSORS
    PROCESSOR_COPY      = "copy"
    PROCESSOR_FFMPEG    = "ffmpeg"
    PROCESSOR_MP4SPLIT  = "mp4split"
    PROCESSORS       = [PROCESSOR_COPY, PROCESSOR_FFMPEG, PROCESSOR_MP4SPLIT]

    # Fields to be imported from params
    IMPORTED = %w(priority pool label priority source target overwrite notify mkdir tempfile transfer transforms)

    # Class options
    attr_accessor :wid

    attr_reader :id

    attr_reader :source_loc
    attr_reader :target_loc

    attr_reader :infos
    attr_reader :error
    attr_reader :status
    attr_reader :tentatives

    attr_reader :created_at
    attr_reader :updated_at
    attr_reader :started_at
    attr_reader :finished_at

    attr_reader :created_since
    attr_reader :started_since
    attr_reader :finished_in

    # Workflow-specific
    attr_reader :tasks
    attr_reader :tempfiles

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
      @wid          = nil
      @tentatives   = 0
      @created_at   = Time.now
      @tempfiles    = [] 

      # Init: worfklow-specific
      @tasks        = []

      # Logger # FIXME: should be :jobs
      log_pipe      :jobs

      # Prepare configuration
      @config       = Conf[:transfer] || {}
      @endpoints    = Conf[:endpoints] || {}

      # Import query params
      set_info INFO_PARAMS, params
      IMPORTED.each do |field|
        instance_variable_set "@#{field}", params[field]
      end

      # Register tasks
      register_tasks

      # Check if pool name exists
      Conf[:pools] ||= {}
      @pool = DEFAULT_POOL unless Conf[:pools].keys.include?(@pool)

      # Prepare sources/target
      raise RestFtpDaemon::JobAttributeMissing, "source" unless params[:source]
      @source_loc = Location.new(params[:source])

      raise RestFtpDaemon::JobAttributeMissing, "target" unless params[:target]
      @target_loc = Location.new(params[:target])
    end

    def reset
      # Update job status
      set_status STATUS_PREPARING

      # Increment run cours
      @tentatives  += 1
      @updated_at   = Time.now
      @started_at   = nil
      @finished_at  = nil

      # Job has been prepared, reset infos
      set_status STATUS_PREPARED
      @infos = {}

      # Reset tasks
      @tasks.map(&:reset)
     
      # Update job status, send first notification
      set_status STATUS_QUEUED
      set_error nil
      job_notify :queued
      log_info "job reset: notify[queued]", {
        pool: @pool,
        source: @source_loc.to_s,
        target: @target_loc.to_s,
        tentative: @tentatives,
      }
    end

    # Process job
    def start
      # Check prerequisites and init
      raise RestFtpDaemon::AssertionFailed, "run/source_loc" unless @source_loc
      raise RestFtpDaemon::AssertionFailed, "run/target_loc" unless @target_loc
      stash = []

      # Notify we start working and remember when we started
      set_status Worker::STATUS_WORKING
      job_notify :started
      @started_at = Time.now

      # Run tasks
      @tasks.each do |task|
        begin
          # Prepare task
          task.input = stash
          task.prepare

          # Run task
          task.status = Task::STATUS_RUNNING
          task.process

          # FIXME Sleep for a few seconds
          sleep JOB_DELAY_TASKS

        rescue StandardError => exception
          # Keep the exception with us
          task.error = exception
          task.status = Task::STATUS_FAILED

          # Close ftp connexion if open
          @remote.close unless @remote.nil? || !@remote.connected?

          # Propagate error to Rollbar
          Rollbar.error exception, "Job.start: error [#{error}]: #{exception.class.name}: #{exception.message}"

          # FIXME: stop tasks from here
          return oops(:task, exception)

        else
          task.status = Task::STATUS_FINISHED
          stash = task.output          

        ensure
          # Always execute do_after
          task.finalize

        end
      end

      # All done !
      set_status STATUS_FINISHED
      # log_info "job_notify: ended"
      job_notify :ended      

      # Identify temp files to be cleant up
      cleanup

      # Update counters
      RestFtpDaemon::Counters.instance.increment :jobs, :finished
    end

    def source_uri
      @source_loc.uri if @source_loc
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
      job_touch
    end

    def job_touch
      now = Time.now
      @updated_at = now
      Thread.current.thread_variable_set :updated_at, now
    end

    def job_notify signal, payload = {}
      # Skip if no URL given
      return unless @notify
      log_info "job_notify: #{signal}"

      # Ok, create a notification!
      payload[:id] = @id
      payload[:signal] = signal
      RestFtpDaemon::Notification.new @notify, payload

    rescue StandardError => ex
      log_error "job_notify EXCEPTION: #{ex.inspect}"
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
      job_touch
    end

    def cleanup
      while f = @tempfiles.pop
        begin
          log_info "cleanup: #{f.name}"
          f.fs_delete
        rescue Errno::ENOENT
          log_debug "   file has already gone"
        end
      end
    end

    def tempfile_for suffix = nil
      # Build file name prefix
      prefix = [:rftpd, @id]
      prefix << suffix unless suffix.nil?
      prefix << ''
    
      # Build a tempfile with a custom name
      temp = Tempfile.new([prefix.join('-'), '.tmp'])
      result = Location.new("file://#{temp.path}")
      temp.close

      # Keep trace of this tempfile
      @tempfiles << result

      # Use this new location
      return result
    end

    def log_context
      {
      wid: @wid,
      jid: @id,
      }
    end

  protected

    def dump title
      log_debug "DUMP [#{@tasks.count}] #{title}"
      @tasks.each do |task|
        task.debug_vars :inputs
        task.debug_vars :outputs
      end
    end

    def alert_common_method_called
      log_error "PLACEHOLDER METHOD CALLED"
    end

  private

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

    # def job_status value
    #   set_status value
    # end  

    # def transfer_flag_import options, name
    #   return unless @transfer.is_a?(Hash)

    #   # Check if flag is already true or false
    #   return unless [true, false].include?(@transfer[name])

    #   # Otherwise, set it to the config value
    #   options[:QUERY] ||= {}
    #   options[:QUERY] << name
    #   options[name] = @transfer[name]
    #   options["#{name}-from"] = :query
    # end

    def oops signal, exception, error = nil#, include_backtrace = false
      # Find error code in ERRORS table
      if error.nil?
        error = JOB_ERRORS.key(exception.class)
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

    def register_task name, config, flavour = nil, options = {}
      # Task class
      clazz = Object.const_get("Task#{name.to_s.capitalize}#{flavour.to_s.capitalize}")

      # Instantiate task
      log_debug "register_task #{clazz.to_s}", options

      # Store it
      @tasks << clazz.new(self, name, config, options)
    end

    def register_tasks
      # FIXME: no config for IMPORT or EXPORT tasks
      transfer_config = Conf.at(:transfer)

      # Register IMPORT
      register_task :import, transfer_config
      
      # Register TRANSFORMS if we have some
      @transforms.each do |tr|
        register_transform(tr)
      end if @transforms.is_a?(Array)

      # Register EXPORT
      register_task :export, transfer_config

      # Announce registered tasks
     # log_debug "registered following tasks", @tasks.map(&:class)
    end

    def register_transform options
      # Check we have a correct config
      return unless options.is_a?(Hash)

      # Raise if this processor does not exist
      processor = options['processor']
      unless PROCESSORS.include?(processor)
        message = "unsupported processor: #{processor}"
        log_error "initialize: #{message}"
        raise RestFtpDaemon::JobUnknownTransform, message
      end

      # Extract options, cleaning processor
      my_options = options.clone
      my_options.delete('processor')

      # Extract transform config from app config
      transform_config = Conf.at(:transforms, processor)

      # Ok to register this task
      register_task :transform, transform_config, processor, my_options
    end

    def load_transform name
      gemname = "rftpd-#{name}"
    end

    # NewRelic instrumentation
    add_transaction_tracer :job_notify,  category: :task
    add_transaction_tracer :initialize,     category: :task

  end
end
