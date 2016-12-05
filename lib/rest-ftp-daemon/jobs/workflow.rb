#FIXME: move progress from Job/infos/transfer to Job/progress

module RestFtpDaemon
  class JobWorkflow < Job

   def do_before
      # Init
      @tasks = [
        TaskImport.new(:import, input: @source_loc),
        TaskTransform.new(:video),
        TaskExport.new(:export, output: @target_loc),
      ]
      #dump :initial
      prev_task = nil

      # Chain every task in the tasks list
      @tasks.each do |task|
        log_info "--- configuring [#{task.name}]"

        # Set task context
        task.log_context = {
          wid: self.wid,
          jid: @id,
          id: task.name,
        }

        # Plug input to previous output
        task.inputs = prev_task.outputs if prev_task

        # Remember pointer to this task
        prev_task = task
      end

      #dump :linked
    end

    def do_work
      # Guess target file name, and fail if present while we matched multiple sources
      # raise RestFtpDaemon::TargetDirectoryError if @target_loc.name && @sources.count>1

      # Run tasks
      @tasks.each do |task|
        task.do_before
        task.work
        task.do_after
       end
    end

    def do_after
    end

  protected

    def dump title
      log_debug "DUMP [#{@tasks.count}] #{title}"
      @tasks.each do |task|
        task.instvar :inputs
        task.instvar :outputs
      end
    end
  end
end
