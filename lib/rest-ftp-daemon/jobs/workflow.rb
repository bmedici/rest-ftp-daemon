#FIXME: move progress from Job/infos/transfer to Job/progress

module RestFtpDaemon
  class JobWorkflow < Job

   def do_before
      # Init
      @tasks = [
        TaskImport.new(     self, :import, input: @source_loc   ),
        TaskTransform.new(  self, :video                        ),
        TaskExport.new(     self, :export, output: @target_loc  ),
      ]
      #dump :initial
      prev_task = nil

      # Chain every task in the tasks list
      @tasks.each do |task|
        log_info "--- configuring [#{task.name}]"

        # Set task context
        task.log_context = {
          wid: self.wid,
          jid: self.id,
          id: task.name,
        }

        # Plug input to previous output
        task.inputs = prev_task.outputs if prev_task

        # Remember pointer to this task
        prev_task = task
      end

      # Prepare flags
      flag_prepare :mkdir
      flag_prepare :overwrite
      flag_prepare :tempfile
      #dump :linked
    end

    def do_work
      # Guess target file name, and fail if present while we matched multiple sources
      # raise RestFtpDaemon::TargetDirectoryError if @target_loc.name && @sources.count>1

      # Run tasks
      @tasks.each do |task|
        log_info "workflow: starting #{task.name}"
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
        task.debug_vars :inputs
        task.debug_vars :outputs
      end
    end
  end
end
