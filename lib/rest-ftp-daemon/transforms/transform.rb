module RestFtpDaemon::Transform
  class ErrorMissingBinary    < BaseException; end
  class ErrorMissingOutput    < BaseException; end
  class ErrorMissingOptions   < BaseException; end
  class ErrorVideoNotFound    < BaseException; end
  class ErrorVideoError       < BaseException; end

  class Base < RestFtpDaemon::Task

    # Task attributes
    def task_icon
      "cog"
    end
 
    # Task operations
    def prepare
      super

      # Ensure options are present
      raise RestFtpDaemon::Transform::ErrorMissingOptions unless @options.is_a? Hash

      # Check we have inputs
      # log_debug "input: #{@input.size} / #{@input.class}"
      raise RestFtpDaemon::SourceNotFound unless @input.is_a?Array
      raise RestFtpDaemon::SourceNotFound if @input.empty?
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
