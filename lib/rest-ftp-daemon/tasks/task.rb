module RestFtpDaemon
  class Task
    include BmcDaemonLib::LoggerHelper

    # Task attributes
    # ICON = "transfer"
    ICON = ""

    # Class options
    # attr_reader :fileset
    attr_reader   :job
    attr_reader   :name
    attr_accessor :log_context

    # Method delegation to parent Job
    delegate :job_notify, :set_status, :set_info, :get_option, :job_touch,
      :source_loc, :target_loc,
      to: :job

    def initialize job, name, opts = {}
      # Init context
      @job          = job
      @name         = name
      @log_context  = {}


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


    def dump_locations name, files
      log_info "task #{name}", files.collect(&:to_s)
    end

      end
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
