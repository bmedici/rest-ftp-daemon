module RestFtpDaemon
  class TaskTransform < Task

    # Task attributes
    # ICON = "facetime-video"
    ICON = "random"
 
    def prepare
    end

    def process
      outputs = []

      # Simulate file transformation
      @inputs.each do |current|
        # Generate temp target from current location       
        target = @job.tempfiles_allocate

        # Fake transformation
        log_debug "do_work fake transform", {
          current: current.to_s,
          target: target.to_s,
          }
        FileUtils.copy_file current.path_abs, target.path_abs
        log_debug "do_work copy results", {
          current_size: current.size,
          target_size: target.size,
          }

        # Add file to output
        output_add target
      end
    end

    def finalize
    end

  protected

  end
end
