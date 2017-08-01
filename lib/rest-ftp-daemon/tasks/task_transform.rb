module RestFtpDaemon::Task
  class TaskTransform < TaskBase

    # Task info
    def task_icon
      "cog"
    end
    def task_name
      "transform"
    end
 
    # Task operations
    def prepare stash
      # Ensure options are present
      raise Transform::TransformMissingOptions unless @options.is_a? Hash

      # Dump file options
      @modifiers = @options["modifiers"]
      log_debug "modifiers", @modifiers

      # Check we have inputs
      # log_debug "input: #{@input.size} / #{@input.class}"
      raise Task::SourceNotFound unless stash.is_a? Hash
      raise Task::SourceNotFound if stash.empty?
    end

  protected

    def init_config
      return unless @plugin.is_a? Array
      _transform, processor, _subprocessor = @plugin
      @config = Conf.at(:transform, processor)
    end

    def transform_each_input stash
      stash.each do |name, loc|
        # Generate temp target from current location
        temp = tempfile_for("transform")

        # Ensure target directory exists
        t_dir = temp.dir_abs
        log_debug "transform mkdir_p [#{t_dir}]"
        FileUtils.mkdir_p t_dir

        # Process this file
        set_info INFO_CURRENT, loc.name
        transform name, loc, temp
        set_info INFO_CURRENT, nil
        @stash_processed += 1

        # Replace loc by this temp file
        stash[name] = temp
      end

      set_info INFO_CURRENT, nil
    end

  end
end
