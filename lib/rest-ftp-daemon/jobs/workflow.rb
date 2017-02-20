#FIXME: move progress from Job/infos/transfer to Job/progress

module RestFtpDaemon
  class JobWorkflow < Job

    def do_after
    end

  protected

    def dump title
      log_debug "DUMP [#{@tasks.count}] #{title}"
      @tasks.each do |task|
        task.debug_vars :inputs
        task.debug_vars :outputs
      end
    end
  end
end
