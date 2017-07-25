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

  class TransferPermissionError   < TaskError; end
  class TransferConnexionFailed    < TaskError; end
  class TransferConnexionInterrupted    < TaskError; end
  class TransferFtpError    < TaskError; end


  class AssertionFailed           < TaskError; end

  # Statuses
  STATUS_READY     = "ready"
  STATUS_RUNNING   = "running"
  STATUS_FINISHED  = "finished"
  STATUS_FAILED    = "failed"


  class Base
    include BmcDaemonLib::LoggerHelper
    include CommonHelpers
    include TaskHelpers

    # Task attributes
    def task_icon; end

    # Class options
    attr_reader   :job
    attr_reader   :name
    attr_reader   :options

    attr_accessor :input
    attr_reader   :output

    attr_accessor :status
    attr_accessor :error
    # attr_accessor :message

    # Method delegation to parent Job
    delegate :job_notify, :set_info, :job_touch,
      :source_loc, :target_loc, :tempfile_for,
      to: :job


    def initialize job, config, options
      # Init context
      @job          = job
      # @name         = name
      @config       = config
      @options      = options

      # Ensure hashes
      @config       = {} unless @config.is_a? Hash
      @options      = {} unless @options.is_a? Hash

      # Enable logging
      log_pipe      :jobs

      reset
    end

    def reset
      @output       = []
      @started_at   = nil
      @finished_at  = nil
      @processed    = 0

      transition_to_ready
    end

      transition_to_running
      log_debug "task config", @config
      log_debug "task options", @options
      log_debug "task input", @input.collect(&:name)

    rescue Errno::ENOTCONN, Errno::EHOSTUNREACH, Errno::ENETUNREACH, Errno::EHOSTDOWN, Errno::ECONNREFUSED => exception
      raise TransferConnexionFailed, exception

    rescue EOFError, Errno::EPIPE, Errno::ECONNRESET => exception
      raise TransferConnexionInterrupted, exception

    rescue Net::FTPConnectionError, Net::FTPPermError, Net::FTPReplyError, Net::FTPTempError, Net::FTPProtoError, Net::FTPError => exception
      raise TransferFtpError, exception

    rescue Net::FTPTempError => exception
      raise TransferPermissionError, exception

    end

    def process
    end

    def finalize
      # # Close ftp connexion if open
      # @remote.close unless @remote.nil? || !@remote.connected?
    end

    def name
      object_to_name(self)
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

    def add_output element
      @output << element
    end

    def transition_to_ready
      log_info "transition to ready"
      @error = nil
      set_status STATUS_READY
    end
    def transition_to_running
      log_info "transition to running"
      set_status STATUS_RUNNING
      @started_at = Time.now
    end

    def transition_to_finished
      log_info "transition to finished"
      @error = nil
      set_status STATUS_FINISHED

      @finished_at = Time.now
      set_status STATUS_FINISHED
    end

    def transition_to_failed error
      log_info "transition to failed"
      @error = error
      set_status STATUS_FAILED
    end


  end
end