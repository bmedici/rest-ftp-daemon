require 'open3'

module RestFtpDaemon
  class TaskTransformMp4split < TaskTransform

    # Task attributes
    def task_icon
      "film"
    end

    # Task operations
    def prepare
      super

      # Init
      @binary = @config[:command]

      # Ensure MP4SPLIT lib is available
      raise RestFtpDaemon::TransformMissingBinary, "mp4split binary not found: #{@config[:command]}" unless File.exist? (@binary)
      raise RestFtpDaemon::TransformMissingBinary, "mp4split binary not executable: #{@config[:command]}" unless File.executable? (@binary)

      # Ensure MP4SPLIT licence is available
      @licence = @config[:licence]
      raise RestFtpDaemon::TransformMissingBinary, "mp4split licence not found: #{@config[:licence]}" unless File.exist? (@licence)

      # Target loc should have a name
      raise RestFtpDaemon::TargetNameRequired, "mp4split requires target to provided a filename"  unless target_loc.name
    end

    def process
      # Prepare input files list
      input_paths = @input.collect(&:path_abs)

      # Generate temp target from current location
      #output = target_loc.clone
      output = tempfile_for("transform")

      # Ensure target directory exists
      t_dir = output.dir_abs
      log_info "mkdir_p [#{t_dir}]"
      FileUtils.mkdir_p t_dir

      # Run command
      transform input_paths, output
    end

  protected

    def transform inputs, output
      # Init
      output_file = output.path_abs
      #log_info "transform output[#{output.name}] input:", @input.collect(&:name)

      # Build params
      params = {}
      params["license-key"] = @licence
      params["hls.client_manifest_version"] = @options["manifest_version"]
      params["hls.minimum_fragment_length"] = @options["minimum_fragment_length"]

      # Run the command
      command = mp4split_command inputs, output_file, params
      log_debug "running command with parameters", command
      stdout, stderr, status = Open3.capture3(*command)

      # Result
      log_debug "command stdout", stdout.split("\n")
      log_debug "command stderr", stderr.split("\n")
      log_info "command status: #{status}"

      # Check we have the expected output file
      raise RestFtpDaemon::TransformMissingOutput, "output file has not been generated: #{output_file}" unless File.exist? (output_file)
    end

  private

    def mp4split_command inputs, output_file, params
      # Build the command
      command = []
      command << @binary

      # Output file
      command << "-o #{output_file}" 

      # Parameters
      params.each do |name, value|
        command << "--#{name}" 
        command << value.to_s
      end

      # Input files
      inputs.each do |input|
        command << input
      end

      # We're all set
      return command
    end

  end
end
