require 'open3'

module RestFtpDaemon::Transform
  class Mp4split < Base

    # Task attributes
    def task_icon
      "film"
    end

    # Task operations
    def prepare
      super

      # Init
      @command = @config[:command]

      # Ensure MP4SPLIT lib is available
      raise RestFtpDaemon::Transform::ErrorMissingBinary, "mp4split binary not found: #{@config[:command]}" unless File.exist? (@command)
      raise RestFtpDaemon::Transform::ErrorMissingBinary, "mp4split binary not executable: #{@config[:command]}" unless File.executable? (@command)

      # Ensure MP4SPLIT licence is available
      @licence = @config[:licence]
      raise RestFtpDaemon::Transform::ErrorMissingBinary, "mp4split licence not found: #{@config[:licence]}" unless @config[:licence]

      # Target loc should have a name
      raise RestFtpDaemon::TargetNameRequired, "mp4split requires target to provided a filename"  unless target_loc.name
    end

    def process
      # Generate temp target from current location
      #output = target_loc.clone
      output = tempfile_for("transform")

      # Ensure target directory exists
      t_dir = output.dir_abs
      log_info "mkdir_p [#{t_dir}]"
      FileUtils.mkdir_p t_dir

      # Run command

      # Build a tempfile with a custom name
      licence_file = Tempfile.new('mp4split-licence-')
      licence_file.write(@licence)
      licence_file.close

      mp4split input, output, licence_file.path
    end

  protected

    def mp4split inputs, output, licence_path
      # Init
      output_file = output.path_abs

      # Build params
      params = {}
      params["license-key"] = licence_path
      params["hls.client_manifest_version"] = @options["manifest_version"]
      params["hls.minimum_fragment_length"] = @options["minimum_fragment_length"]

      # Run the command
      command = mp4split_command output_file, params
      log_debug "running command with parameters", command
      stdout, stderr, status = Open3.capture3(*command)

      # Result
      log_info "result pid[#{status.pid}] exitstatus[#{status.exitstatus}] success[#{status.success?}]", stdout.lines
      log_debug "command stderr", stderr.lines unless stderr.blank?

      # If we get anything on stderr => failed
      unless status.success?
        raise RestFtpDaemon::TaskFailed, "stderr: #{stderr}"
      end

      # Check we have the expected output file
      unless File.exist? (output_file)
        raise RestFtpDaemon::Transform::ErrorMissingOutput, "can't find the expected output file at: #{output_file}"
      end
    end

  private

    def mp4split_command output_file, params
      # Build the command
      command = []
      command << @command

      # Output file
      command << "-o #{output_file}" 

      # Parameters
      params.each do |name, value|
        command << "--#{name}" 
        command << value.to_s
      end

      # Input files
      @input.each do |input|
        command << input.path_abs
      end

      # We're all set
      return command
    end

  end
end
