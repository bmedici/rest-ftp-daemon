# Dependencies
require "rest-ftp-daemon"

# Simple file copy, mainly for testing purposes
module RestFtpDaemon::Transform
  class TransformCopy < TaskTransform

    def process
      transform_each_input
    end

  protected

    def transform input, output
      # Fake transformation
      FileUtils.copy_file input.path_abs, output.path_abs

      log_debug "copy results", {
        input_size: input.size,
        output_size: output.size,
        }
    end

  end
end