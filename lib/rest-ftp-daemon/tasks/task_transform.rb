module RestFtpDaemon
  class TaskTransform < Task

    # Task attributes
    def task_icon
      "cog"
    end
 
    # Task operations
    def prepare
      super

      # Ensure options are present
      raise RestFtpDaemon::TransformMissingOptions unless @options.is_a? Hash
      log_debug "options", @options

      # Check we have inputs
      raise RestFtpDaemon::SourceNotFound if @job.units.empty?
      raise RestFtpDaemon::SourceNotFound unless @options.is_a? Hash
      # log_debug "input: #{@input.size} / #{@input.class}"
      raise RestFtpDaemon::SourceNotFound unless @input.is_a?Array
      raise RestFtpDaemon::SourceNotFound if @input.empty?

    end

    def process
      outputs = []

      # Simulate file transformation
        # Generate temp target from current location       
        target = @job.tempfiles_allocate

        # Fake transformation
        log_debug "fake transform (copy)", {
          current: current.to_s,
          target: target.to_s,
          }
        FileUtils.copy_file current.path_abs, target.path_abs
        log_debug "fake transform results", {
          current_size: current.size,
          target_size: target.size,
          }
      @input.each do |loc|

        # Replace loc by this tempfile
        add_output tempfile
      end
    end

    def finalize
    end

  end
end
