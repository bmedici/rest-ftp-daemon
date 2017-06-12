module RestFtpDaemon
  class TaskTransform < Task

    # Task attributes
    # ICON = "facetime-video"
    ICON = "random"
 
      # Check input
      @inputs = @job.stash.clone
      unless @inputs.is_a? Array
        raise RestFtpDaemon::SourceUnsupported, "task inputs: invalid file list"
      end
    def prepare
    end

    def process
      outputs = []

      # Simulate file transformation
      @inputs.each do |current|
        # Generate target from current location
        log_debug "do_work 1: #{current.to_s}"
        target = current.clone
        log_debug "do_work 2: #{current.to_s}"
        target.generate_temp_name!
        log_debug "do_work 3: #{current.to_s}"

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
        add_output target
      end
    end

    def finalize
    end

  protected

  end
end
