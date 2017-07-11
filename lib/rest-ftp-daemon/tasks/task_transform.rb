module RestFtpDaemon
  class TransformMissingBinary    < BaseException; end
  class TransformMissingOutput    < BaseException; end
  class TransformMissingOptions   < BaseException; end
  class TransformVideoNotFound    < BaseException; end
  class TransformVideoError       < BaseException; end

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

      # Check we have inputs
      # log_debug "input: #{@input.size} / #{@input.class}"
      raise RestFtpDaemon::SourceNotFound unless @input.is_a?Array
      raise RestFtpDaemon::SourceNotFound if @input.empty?
    end

  protected

    def transform_each_input
      @input.each do |loc|
        # This location is the source and will be replaced byt the target
        # log_info "loc id: #{loc.object_id}"

        # Generate temp target from current location
        tempfile = tempfile_for("transform")

        # Ensure target directory exists
        t_dir = tempfile.dir_abs
        log_debug "transform mkdir_p [#{t_dir}]"
        FileUtils.mkdir_p t_dir

        # Process this file
        # log_debug "transform input[#{loc.name}] output[#{tempfile.name}]"
        set_info INFO_CURRENT, loc.name
        transform loc, tempfile

        # Replace loc by this tempfile
        add_output tempfile
      end

      set_info INFO_CURRENT, nil
    end

  end
end
