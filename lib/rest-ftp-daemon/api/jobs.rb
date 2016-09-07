require "grape"

module RestFtpDaemon
  module API
    class Jobs < Grape::API
      include BmcDaemonLib

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
        begin
          # Get job to display
          raise RestFtpDaemon::JobNotFound if params[:id].nil?
          job = RestFtpDaemon::JobQueue.instance.find_by_id(params[:id]) || RestFtpDaemon::JobQueue.instance.find_by_id(params[:id], true)
          raise RestFtpDaemon::JobNotFound if job.nil?

          log_debug "found job: #{job.inspect}"

        rescue RestFtpDaemon::JobNotFound => exception
          log_error "JobNotFound: #{exception.message}"
          error!({ error: :api_job_not_found, message: exception.message }, 404)

        rescue StandardError => exception
          log_error "Exception: #{exception.message}"
          error!({ error: :api_exception, message: exception.message }, 500)

        else
          status 200
          present job, with: RestFtpDaemon::Entities::Job, type: "complete"

        end
      end

      desc "List all Jobs", http_codes: [
        { code: 200, message: "Here are the jobs you requested" },
        ],
        is_array: true
      get "/" do
        begin
          # Get jobs to display
          jobs = RestFtpDaemon::JobQueue.instance.jobs

        rescue StandardError => exception
          log_error "Exception: #{exception.message}"
          error!({ error: :api_exception, message: exception.message }, 500)

        else
          status 200
          present jobs, with: RestFtpDaemon::Entities::Job

        end
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
           optional :video_codec,             type: String
           optional :video_bitrate,           type: String
           optional :video_bitrate_tolerance, type: String
           optional :frame_rate,              type: Integer
           optional :resolution,              type: String
           optional :aspect,                  type: String
           optional :keyframe_interval,       type: String
           optional :x264_vprofile,           type: String
           optional :x264_preset,             type: String
           optional :audio_codec,             type: String
           optional :audio_bitrate,           type: String
           optional :audio_sample_rate,       type: Integer
           optional :audio_channels,          type: String
        end

        optional :video_custom,
          type: Hash,
          desc: "video: custom options passed to FFMPEG encoder",
          default: {}

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
        # log_debug params.to_json
        begin
          # Add up the new job on the queue
          job = RestFtpDaemon::JobQueue.instance.create_job(params)

          # Increment a counter
          RestFtpDaemon::Counters.instance.increment :jobs, :received

        rescue JSON::ParserError => exception
          log_error "JSON::ParserError: #{exception.message}"
          error!({error: :api_parse_error, message: exception.message}, 422)

        rescue QueueCantCreateJob => exception
          log_error "QueueCantCreateJob: #{exception.message}"
          error!({error: :api_cant_create_job, message: exception.message}, 422)

        rescue RestFtpDaemonException => exception
          log_error "#{exception.class.to_s} #{exception.message}"
          error!({error: exception_to_error(exception), message: exception.message}, 500)

        else
          status 201
          present job, with: RestFtpDaemon::Entities::Job, hide_params: true

        end
      end

    end
  end
end
