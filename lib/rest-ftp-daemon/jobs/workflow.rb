#FIXME: move progress from Job/infos/transfer to Job/progress

module RestFtpDaemon
  class JobWorkflow < Job

  protected

    def do_before
      # Init
      pipe = {
        import: TaskImport,
        transf: TaskTransform,
        export: TaskExport,
      }
      @tasks = {}

      # First input is provided
      (in1 = @source_loc.clone).name = "in1"
      (in2 = @source_loc.clone).name = "in2"
      (in3 = @source_loc.clone).name = "in3"
      current = [in1, in2, in3]
      log_debug "WORKFLOW INPUTS", current.map(&:path)

      # Chain every task in the pipe
      pipe.each do |name, family|

        @tasks[name] = task
        # Set task context
        task.log_context = {
          wid: self.wid,
          jid: @id,
          id: task.name,
        }

        # Plug input to previous output
        task.inputs = current

        # Remember pointer to this output
        current = task.outputs
      end
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
