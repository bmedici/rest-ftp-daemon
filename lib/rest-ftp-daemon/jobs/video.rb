require 'streamio-ffmpeg'

module RestFtpDaemon
  class JobVideo < Job

    # Process job
    def before
      log_info "JobVideo.before source_loc.path: #{@source_loc.path}"
      log_info "JobVideo.before target_loc.path: #{@target_loc.path}"

      # Ensure source and target are FILE
      raise RestFtpDaemon::SourceNotSupported, @source_loc.scheme   unless source_uri.is_a? URI::FILE
      raise RestFtpDaemon::TargetNotSupported, @target.scheme       unless target_uri.is_a? URI::FILE
    end

    def work





    rescue FFMPEG::Error => exception
      return oops :ended, exception, "ffmpeg_error"
    end

    def after
      # Done
      set_info :source, :current, nil
    end


    def video_command source, target
      log_info "JobVideo.video_command [#{source.name}]: [#{source.full}] > [#{target.full}]"
      set_info :source, :current, source.name

      # Read info about source file
      movie = FFMPEG::Movie.new(source.full)
      #set_info :source_video, :total, @transfer_total

      # Build options
      ffmpeg_cutsom_options = {
        audio_codec: @video_ac,
        video_codec: @video_vc,
        custom: ffmpeg_custom_option_array,
        }
      set_info :video, :ffmpeg_cutsom_options, ffmpeg_cutsom_options

      # Build command
      movie.transcode(target.full, ffmpeg_cutsom_options) do |ffmpeg_progress|
        set_info :video, :ffmpeg_progress, ffmpeg_progress

        percent0 = (100.0 * ffmpeg_progress).round(0)
        set_info :transfer, :progress, percent0

        log_debug "progress #{ffmpeg_progress}"
      end

    end

  private

    def ffmpeg_custom_option_array
      # Ensure options ar in the correct format
      return [] unless @video_custom.is_a? Hash
      # video_custom_parts = @video_custom.to_s.scan(/(?:\w|"[^"]*")+/)

      # Build the final array
      custom_parts = []
      @video_custom.each do |name, value|
        custom_parts << "-#{name}"
        custom_parts << value.to_s
      end

      # Return this
      return custom_parts
    end

  end
end



