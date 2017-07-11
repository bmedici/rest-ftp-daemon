require "grape"

module RestFtpDaemon
  module API
    class Jobs < Grape::API
      include BmcDaemonLib

      ### HELPERS
      helpers do
        def log_context
          {caller: "API::Jobs"}
        end
      end

      ### EXCEPTIONS HANDLERS
      rescue_from RestFtpDaemon::JobNotFound do |exception|
        exception_error :api_job_not_found, 404, exception
      end
      rescue_from JSON::ParserError do |exception|
        exception_error :api_parse_error, 422, exception
      end
      # rescue_from RestFtpDaemon::QueueCantCreateJob do |exception|
      #   exception_error :api_cant_create_job, 422, exception
      # end
      rescue_from RestFtpDaemon::JobUnresolvedTokens do |exception|
        exception_error :api_unresolved_tokens, 422, exception
      end

      ### ENDPOINTS
      desc "Read job with ID", http_codes: [
        { code: 200, message: "Here is the job you requested" },
        { code: 404, message: "Job not found" }
        ],
        is_array: false,
        tags: ['jobs']
      params do
        requires :id, type: String, desc: "ID of the Job to read"
      end
      get "/:id", requirements: { id: /.*/ } do
        # Get job to display
        raise RestFtpDaemon::JobNotFound if params[:id].nil?
        job = RestFtpDaemon::JobQueue.instance.find_by_id(params[:id]) || RestFtpDaemon::JobQueue.instance.find_by_id(params[:id], true)
        raise RestFtpDaemon::JobNotFound if job.nil?
        log_debug "found job: #{job.inspect}"

        # Prepare response
        status 200
        present job, with: RestFtpDaemon::Entities::Job, type: "complete"
      end

      desc "List all Jobs", http_codes: [
        { code: 200, message: "Here are the jobs you requested" },
        ],
        is_array: true,
        tags: ['jobs']
      get "/" do
        # Get jobs to display
        jobs = RestFtpDaemon::JobQueue.instance.jobs

        # Prepare response
        status 200
        present jobs, with: RestFtpDaemon::Entities::Job
      end

      desc "Create a new job"
      params do
        requires :source,
          type: String,
          desc: "Source file pattern",
          allow_blank: false
        requires :target,
          type: String,
          desc: "Target remote path",
          allow_blank: false
        optional :label,
          type: String,
          desc: "Descriptive label (info only)"

        optional :notify,
          type: String,
          desc: "URL to get POST'ed notifications back",
          allow_blank: false
        optional :pool,
          type: String,
          desc: "Pool of worker to be used",
          default: Job::DEFAULT_POOL
        optional :priority,
          type: Integer,
          desc: "Priority level of the job (lower is stronger)",
          default: 0


        optional :transfer, type: Hash, desc: "transfer options", documentation: { collectionFormat: 'multi' } do
          optional :overwrite,
            type: Boolean,
            desc: "Overwrites files at target server",
            default: Conf.at(:transfer, :overwrite)
          optional :mkdir,
            type: Boolean,
            desc: "Create missing directories on target server",
            default: Conf.at(:transfer, :mkdir)
          optional :tempfile,
            type: Boolean,
            desc: "Upload to a temp file before renaming it to the target filename",
            default: Conf.at(:transfer, :tempfile)
        end

        optional :transforms, type: Array, desc: "transform options", documentation: { hidden: true, collectionFormat: 'multi' } do
          requires :processor,
            type: String,
            desc: "Processor used on this transformation",
            values: Job::PROCESSORS
            # values: {value: TaskTransform::TYPES, message: "should be one of: #{TaskTransform::TYPES.join(', ')}"}

          given processor: ->(val) { val == PROCESSOR_COPY } do
            optional :really
          end

          # given processor: ->(val) { val == PROCESSOR_FFMPEG } do
          #   optional :audio_codec,             type: String,  desc: "ffmpeg: audio codec (ex: copy, libfaac, ibfdk_aac)"
          #   optional :audio_bitrate,           type: String,  desc: "ffmpeg: nominal audio bitrate"
          #   optional :audio_sample_rate,       type: Integer, desc: "ffmpeg: audio sampling rate"
          #   optional :audio_channels,          type: String,  desc: "ffmpeg: number of audio channels"

          #   optional :video_codec,             type: String,  desc: "ffmpeg: video codec (ex: copy, libx264)"
          #   optional :video_bitrate,           type: String,  desc: "ffmpeg: nominal video bitrate"
          #   optional :video_bitrate_tolerance, type: String,  desc: "ffmpeg: maximum video bitrate"

          #   optional :frame_rate,              type: Integer, desc: "ffmpeg: output frames per second"
          #   optional :resolution,              type: String,  desc: "ffmpeg: output video resolution"
          #   optional :aspect,                  type: String,  desc: "ffmpeg: output aspect ratio"
          #   optional :keyframe_interval,       type: String,  desc: "ffmpeg: group of pictures (GOP) size"
          #   optional :x264_vprofile,           type: String,  desc: "ffmpeg: h264 profile"
          #   optional :x264_preset,             type: String,  desc: "ffmpeg: h264 preset (fast, low..)"
          # end

          # given processor: ->(val) { val == PROCESSOR_MP4SPLIT } do
          #   optional :manifest_version,        type: String,  desc: "mp4split: manifest_version"
          #   optional :minimum_fragment_length, type: String,  desc: "mp4split: minimum_fragment_length"
          # end

        end


        #, using: Entities::Transform.documentation
        # optional :transforms2, type: Collection, desc: "transform options", using: Entities::Transform.documentation

      end

      post "/" do
        # Add up the new job on the queue
        job = RestFtpDaemon::JobQueue.instance.create_job(params)

        # Increment a counter
        RestFtpDaemon::Counters.instance.increment :jobs, :received

        # Prepare response
        status 201
        present job, with: RestFtpDaemon::Entities::Job, hide_params: true
      end

    end
  end
end