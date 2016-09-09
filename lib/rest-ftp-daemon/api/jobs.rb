require "grape"

module RestFtpDaemon
  module API
    class Jobs < Grape::API
      include BmcDaemonLib

      ### EXCEPTIONS HANDLERS
      rescue_from RestFtpDaemon::JobNotFound do |exception|
        exception_error :api_job_not_found, 404, exception
      end
      rescue_from JSON::ParserError do |exception|
        exception_error :api_parse_error, 422, exception
      end
      rescue_from RestFtpDaemon::QueueCantCreateJob do |exception|
        exception_error :api_cant_create_job, 422, exception
      end
      rescue_from RestFtpDaemon::JobUnresolvedTokens do |exception|
        exception_error :api_unresolved_tokens, 422, exception
      end


      ### ENDPOINTS
      desc "Read job with ID", http_codes: [
        { code: 200, message: "Here is the job you requested" },
        { code: 404, message: "Job not found" }
        ],
        is_array: false
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
        is_array: true
      get "/" do
        # Get jobs to display
        jobs = RestFtpDaemon::JobQueue.instance.jobs

        # Prepare response
        status 200
        present jobs, with: RestFtpDaemon::Entities::Job
      end

      desc "Create a new job"
     # desc 'Creates a new app' do
     #    detail 'It is used to register a new app on the server and get the app_id'
     #    params Entities::AppsParamsEntity.documentation
     #    success Entities::AppsEntity
     #    failure [[400, 'Bad Request', Entities::ErrorEntity]]
     #    named 'create app'
     #  end

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
        optional :type,
          type: String,
          desc: "Type of job",
          default: JOB_TYPE_TRANSFER,
          values: {value: JOB_TYPES, message: "should be one of: #{JOB_TYPES.join', '}"},
          allow_blank: { value: false, message: 'cannot be empty' }
        optional :pool,
          type: String,
          desc: "Pool of worker to be used",
          default: DEFAULT_POOL
        optional :priority,
          type: Integer,
          desc: "Priority level of the job (lower is stronger)",
          default: 0

        optional :video_options, type: Hash, desc: "Options passed to FFMPEG encoder", default: {} do
           optional :video_codec,             type: String,  desc: "video codec (ex: copy, libx264)"
           optional :video_bitrate,           type: String,  desc: "nominal video bitrate"
           optional :video_bitrate_tolerance, type: String,  desc: "maximum video bitrate"
           optional :frame_rate,              type: Integer, desc: "output frames per second"
           optional :resolution,              type: String,  desc: "output video resolution"
           optional :aspect,                  type: String,  desc: "output aspect ratio"
           optional :keyframe_interval,       type: String,  desc: "group of pictures (GOP) size"
           optional :x264_vprofile,           type: String,  desc: "h264 profile"
           optional :x264_preset,             type: String,  desc: "h264 preset (fast, low..)"
           optional :audio_codec,             type: String,  desc: "audio codec (ex: copy, libfaac, ibfdk_aac)"
           optional :audio_bitrate,           type: String,  desc: "nominal audio bitrate"
           optional :audio_sample_rate,       type: Integer, desc: "audio sampling rate"
           optional :audio_channels,          type: String,  desc: "number of audio channels"
        end

        optional :video_custom,
          type: Hash,
          desc: "video: custom options passed to FFMPEG encoder",
          default: {}

        optional :options, type: Hash, desc: "Options for transfers" do
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
        # given :shelf_id do
        #   requires :bin_id, type: Integer
        # end
        # given category: ->(val) { val == 'foo' } do
        #   requires :description
        # end
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
