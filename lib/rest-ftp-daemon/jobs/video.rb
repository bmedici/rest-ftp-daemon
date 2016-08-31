require 'streamio-ffmpeg'

module RestFtpDaemon
  class JobVideo < Job

    def process
      log_info "JobVideo.process update_interval:#{JOB_UPDATE_INTERVAL}"

      # Prepare job
      begin
        prepare_common
        prepare_local

      rescue RestFtpDaemon::JobMissingAttribute => exception
        return oops :started, exception, "missing_attribute"

      else
        set_status JOB_STATUS_PREPARED
      end

      # Process job
      begin
        log_info "JobVideo.process notify [started]"
        client_notify :started
        run

      rescue FFMPEG::Error => exception
        return oops :ended, exception, "ffmpeg_error"

      else
        set_status JOB_STATUS_FINISHED
        log_info "JobVideo.process notify [ended]"
        client_notify :ended
      end
    end


  def prepare_local
    # Prepare flags
    # flag_prepare :mkdir, false

    # Update job status

  end


  def run
      # Update job status
      set_status JOB_STATUS_RUNNING
      @started_at = Time.now

      # Method assertions and init
      raise RestFtpDaemon::JobAssertionFailed, "run/1" unless @source_path
      raise RestFtpDaemon::JobAssertionFailed, "run/2" unless @target_path

      # Guess source files from disk
      set_status JOB_STATUS_CHECKING_SRC
      sources = find_local @source_path
      set_info :source, :count, sources.count
      set_info :source, :files, sources.collect(&:full)
      log_info "JobVideo.run sources #{sources.collect(&:name)}"
      raise RestFtpDaemon::JobSourceNotFound if sources.empty?

      # Guess target file name, and fail if present while we matched multiple sources
      raise RestFtpDaemon::JobTargetDirectoryError if @target_path.name && sources.count>1

      # Connect to remote server and login
      set_status JOB_STATUS_CONNECTING

      # Handle each source file matched, and start a transfer
      source_processed = 0
      targets = []
      sources.each do |source|
        # Compute target filename
        full_target = @target_path.clone
        log_info "JobVideo.run source: #{source.name}"
        log_info "JobVideo.run target_path: #{@target_path.inspect}"
        log_info "JobVideo.run full_target: #{full_target.inspect}"

        # Add the source file name if none found in the target path
        unless full_target.name
          full_target.name = source.name
        end

        # Do the transfer, for each file
        video_command source, full_target

        # Add it to transferred target names
        targets << full_target.full
        set_info :target, :files, targets

        # Update counters
        set_info :source, :processed, source_processed += 1
      end

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



