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
      ffmpeg_binary_path = FFMPEG.ffmpeg_binary
      unless ffmpeg_binary_path && File.exists?(ffmpeg_binary_path)
        raise RestFtpDaemon::MissingFfmpegLibraries, ffmpeg_binary_path
      end

      # Ensure source and target are FILE
      raise RestFtpDaemon::SourceNotSupported, @source_loc.scheme   unless source_uri.is_a? URI::FILE
      raise RestFtpDaemon::TargetNotSupported, @target.scheme       unless target_uri.is_a? URI::FILE
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
      set_info :source, :current, @source_loc.name
      ffmpeg_command @source_loc, target_final

      # Done
      set_info :source, :current, nil
    end

    def do_after
      # Done
      set_info :source, :current, nil
    end

    def ffmpeg_command source, target
      set_info :source, :current, source.name

      # Read info about source file
      movie = FFMPEG::Movie.new(source.path)

      # Build options
      options = {
        threads: JOB_FFMPEG_THREADS
        }
      options[:audio_codec] = @video_ac                    unless @video_ac.to_s.empty?
      options[:video_codec] = @video_vc                    unless @video_vc.to_s.empty?
      options[:custom]      = options_from(@video_custom)  if @video_custom.is_a? Hash

      set_info :work, :ffmpeg_options, options

      # Announce contexte
      log_info "JobVideo.ffmpeg_command [#{FFMPEG.ffmpeg_binary}] [#{source.name}] > [#{target.name}]", options

      # Build command
      movie.transcode(target.path, options) do |ffmpeg_progress|
        set_info :work, :ffmpeg_progress, ffmpeg_progress

        percent0 = (100.0 * ffmpeg_progress).round(0)
        set_info :work, :progress, percent0

        log_debug "progress #{ffmpeg_progress}"
      end
    end

    def options_from attributes
      # Ensure options ar in the correct format
      return [] unless attributes.is_a? Hash
      # video_custom_parts = @video_custom.to_s.scan(/(?:\w|"[^"]*")+/)

      # Build the final array
      custom_parts = []
      attributes.each do |name, value|
        custom_parts << "-#{name}"
        custom_parts << value.to_s
      end

      # Return this
      return custom_parts
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
