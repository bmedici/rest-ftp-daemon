module RestFtpDaemon
  class Task
    include BmcDaemonLib::LoggerHelper
    include CommonHelpers

    # Task attributes
    # ICON = "transfer"
    ICON = ""

    # Class options
    attr_reader   :job
    attr_reader   :name
    attr_accessor :error
    attr_reader   :outputs
    attr_accessor :log_context

    # Method delegation to parent Job
    delegate :job_notify, :set_status, :set_info, :get_option, :job_touch,
      :source_loc, :target_loc,
      to: :job

    def initialize job, name #, opts = {}
      # Init context
      @job          = job
      @name         = name
      @log_context  = {}
      @error        = nil
      @outputs      = []

      # Prepare configuration / import a copy
      # @config       = Conf[:transfer].clone || {}
      @config       = Conf.at(:transfer) || {}

      # Enable logging
      log_pipe      :workflow
    end

    def do_before
    end

    def do_work
    end

    def do_after
    end

  protected

    def debug_vars var
      items = instance_variable_get("@#{var}")

      if items.is_a? Array
        log_debug "#{var}  \t #{items.object_id}", items.map(&:path)
      else
        log_error "#{var}  \t NOT AN ARRAY" 
      end
    end

    def add_output output
      @outputs << output
    end

    def derivate_temp_location loc
      temp = loc.clone
      temp.generate_temp_name!
      #temp.name = "#{temp.name}-{temp}"
      return temp
    end

    def task_oops exception, error = nil#, include_backtrace = false
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

    def set_info name, value
      @job.set_info name, value
    end

    def set_status value
      @job.set_status value
      #@job.set_status value
    end

  private
      
    # def log_context
    #   {
    #     wid: @wid,
    #     jid: @jid,
    #     id: name
    #   }
    # end

  end
end
