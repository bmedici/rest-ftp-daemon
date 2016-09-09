# FIXME: handle overwrite
# FIXME: progress over multiple files
# FIXME: open movie files to guess total runtime
# FIXME: analyze media files at prepare

require 'streamio-ffmpeg'

module RestFtpDaemon
  class JobVideo < Job

  protected

    # Process job
    def do_before
      log_info "JobVideo.before source_loc.path: #{@source_loc.path}"
      log_info "JobVideo.before target_loc.path: #{@target_loc.path}"

      # Ensure FFMPEG lib is available
      check_ffmpeg_binary :ffmpeg_binary
      check_ffmpeg_binary :ffprobe_binary

      # Ensure source and target are FILE
      raise RestFtpDaemon::AssertionFailed                         unless @video_options.is_a? Hash
      raise RestFtpDaemon::AssertionFailed                         unless @video_custom.is_a? Hash
      raise RestFtpDaemon::SourceUnsupported, @source_loc.scheme   unless @source_loc.is? URI::FILE
      raise RestFtpDaemon::TargetUnsupported, @target_loc.scheme   unless @target_loc.is? URI::FILE
    end

    def do_work
      # Guess source files from disk
      set_status JOB_STATUS_TRANSFORMING
      sources = @source_loc.scan_files
      raise RestFtpDaemon::SourceNotFound if sources.empty?

      # Add the source file name if none found in the target path
      target_final = @target_loc.clone
      target_final.name = @source_loc.name unless target_final.name
      log_info "JobVideo.work target_final.path [#{target_final.path}]"

      # Ensure target directory exists
      log_info "JobVideo.work mkdir_p [#{@target_loc.dir}]"
      FileUtils.mkdir_p @target_loc.dir

      # Do the work, for each file
      set_info INFO_SOURCE_CURRENT, @source_loc.name
      ffmpeg_command @source_loc, target_final

      # Done
      set_info INFO_SOURCE_CURRENT, nil
    end

    def do_after
      # Done
      set_info INFO_SOURCE_CURRENT, nil
    end

    def ffmpeg_command source, target
      # Read info about source file
      set_info INFO_SOURCE_CURRENT, source.name
      begin
        movie = FFMPEG::Movie.new(source.path)
      rescue StandardError => exception
        raise RestFtpDaemon::VideoMovieError, exception.message
      else
        set_info :ffmpeg_size, movie.size
        set_info :ffmpeg_duration, movie.duration
        set_info :ffmpeg_resolution, movie.resolution
      end

      # Build options
      options = {
        threads: JOB_FFMPEG_THREADS,
        custom: options_from(@video_custom)
        }
      JOB_FFMPEG_ATTRIBUTES.each do |name|
        options[name] = @video_options[name] unless @video_options[name].nil?
      end
      set_info :work_ffmpeg_options, options

      # Announce context
      log_info "JobVideo.ffmpeg_command [#{FFMPEG.ffmpeg_binary}] [#{source.name}] > [#{target.name}]", options

      # Build command
      movie.transcode(target.path, options) do |ffmpeg_progress|
        # set_info :work, :ffmpeg_progress, ffmpeg_progress
        set_info INFO_TRANFER_PROGRESS, (100.0 * ffmpeg_progress).round(1)
        log_debug "progress #{ffmpeg_progress}"
      end
    end

    def options_from attributes
      # Ensure options ar in the correct format
      return [] unless attributes.is_a? Hash

      # Build the final array
      custom_parts = []
      attributes.each do |name, value|
        custom_parts << "-#{name}"
        custom_parts << value.to_s
      end

      # Return this
      return custom_parts
    end

    def check_ffmpeg_binary method
      # Get or evaluate the path which can raise a Errno::ENOENT
      path = FFMPEG.send method

      # Check that it returns something which exists on disk
      raise StandardError unless path && File.exists?(path)

    rescue StandardError, Errno::ENOENT => exception
      raise RestFtpDaemon::VideoMissingBinary, "missing ffmpeg binary: #{method}"
    end

  end
end


# require "stringio"
# def capture_stderr
#   real_stderr, $stderr = $stderr, StringIO.new
#   yield
#   $stderr.string
# ensure
#   $stderr = real_stderr
# end
