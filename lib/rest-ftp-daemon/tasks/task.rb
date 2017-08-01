module RestFtpDaemon::Task
  class TaskError                 < StandardError; end

  class SourceUnsupported         < TaskError; end
  class SourceNotFound            < TaskError; end
  class SourceShouldBeUnique      < TaskError; end

  class TargetFileExists          < TaskError; end
  class TargetDirectoryError      < TaskError; end
  class TargetPermissionError     < TaskError; end
  class TargetUnsupported         < TaskError; end
  class TargetNameRequired        < TaskError; end

  class TransferPushError          < TaskError; end
  class TransferFtpError          < TransferError; end
  class TransferInterrupted       < TransferError; end
  class TransferConnexionError    < TransferError; end
  class TransferPermissionError   < TransferError; end

  class AssertionFailed           < TaskError; end

  class TaskBase
    include BmcDaemonLib::LoggerHelper
    include CommonHelpers
    include TaskHelpers

    # Task statuses
    STATUS_READY     = "ready"
    STATUS_RUNNING   = "running"
    STATUS_FINISHED  = "finished"
    STATUS_FAILED    = "failed"

    # Task info
    def task_icon
    end
    def task_name
    end

    # Class options
    attr_reader   :job
    attr_reader   :name
    attr_reader   :options

    attr_accessor :status
    attr_accessor :error
    # attr_accessor :message

    # Method delegation to parent Job
    delegate :job_notify, :set_info, :job_touch,
      :source_loc, :target_loc, :tempfile_for,
      to: :job


    def initialize job, options, plugin = {}
      # Init context
      @job          = job
      @options      = options
      @plugin       = plugin

      # Enable logging
      log_pipe      :jobs
     
      # Import options
      @options      = {} unless @options.is_a? Hash
      log_debug "task options #{@options.to_hash.inspect}"

      # Init config
      init_config
      @config ||= {empty: true}
      log_debug "task config #{@config.to_hash.inspect}"

      # Reset data
      reset
    end

    def reset
      @processed    = 0
      # @output       = []
      @started_at         = nil
      @finished_at        = nil

      transition_to_ready
    end

    def run stash
      transition_to_running

      # Import input from stash
      # @input = stash
      @stash_size = stash.size

      # Some debug
      log_debug "stash input", stash.keys

      # Prepare task
      prepare(stash)

      # Process task
      process(stash)

    rescue Errno::ENOENT => exception
      transition_to_failed exception
      raise Transform::TransformFileNotFound, exception

    rescue TransferConnexionError, TransferInterrupted, TransferError => exception
      transition_to_failed exception
      raise

    rescue Exception => exception
      # Always finalize
      finalize
      # log_info "unknwon exception caught: #{exception.inspect}"

      # Re-raise this exception upwards
      transition_to_failed exception
      raise

    else
      # Always finalize
      finalize

      # This is our result
      transition_to_finished
      #return @output

    ensure
      # Always finalize
      sleep JOB_DELAY_TASKS
    end

    def process
    end

    def finalize
      # # Close ftp connexion if open
      # @remote.close unless @remote.nil? || !@remote.connected?
    end

    def log_context
      @job.log_context
    end

    end

  protected

    def get_flag name
      return @options[name] if [true, false].include? @options[name]
      return @config[name]
    end

    def set_info name, value
      @job.set_info name, value
    end

    def set_status value
      @status = value
    end

    # def add_output element
    #   @output << element
    # end

    def transition_to_ready
      log_info "task [ready]"
      @error = nil
      set_status STATUS_READY
    end
    def transition_to_running
      log_info "task [running]"
      set_status STATUS_RUNNING
      @started_at = Time.now
    end

    def transition_to_finished
      log_info "task [finished]"
      @error = nil
      set_status STATUS_FINISHED

      @finished_at = Time.now
      set_status STATUS_FINISHED
    end

    def transition_to_failed error
      log_info "task [failed]"
      @error = error
      set_status STATUS_FAILED
    end


  end
end