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
      # Run tasks
      @tasks.each do |n, t|
        t.do_before
        t.work
        t.do_after
       end
    end

    def do_after
    end

  end
end
