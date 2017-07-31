module RestFtpDaemon::Transform
  class TransformError            < RestFtpDaemon::Task::TaskError; end

  class TransformMissingBinary    < TransformError; end
  class TransformMissingOutput    < TransformError; end
  class TransformMissingOptions   < TransformError; end

  class TaskTransform < RestFtpDaemon::Task::TaskBase
    # Task info
    def task_icon
      "cog"
    end
    def task_name
      "transform"
    end

    # Available plugins detection
    def self.available
      Pluginator.
        find(Conf.app_name, extends: %i[plugins_map]).
        plugins_map(PLUGIN_TRANSFORM).
        keys
    end
 
    # Task operations
    def prepare
      # Ensure options are present
      raise Transform::TransformMissingOptions unless @options.is_a? Hash

      # Check we have inputs
      # log_debug "input: #{@input.size} / #{@input.class}"
      raise Task::SourceNotFound unless @input.is_a?Array
      raise Task::SourceNotFound if @input.empty?
    end

  protected

    def transform_each_input
      @input.each do |loc|
        # Generate temp target from current location
        tempfile = tempfile_for("transform")

        # Ensure target directory exists
        t_dir = tempfile.dir_abs
        log_debug "transform mkdir_p [#{t_dir}]"
        FileUtils.mkdir_p t_dir

        # Process this file
        set_info INFO_CURRENT, loc.name
        transform loc, tempfile

        # Replace loc by this tempfile
        add_output tempfile
      end

      set_info INFO_CURRENT, nil
    end

  end
end
