require "grape"

module RestFtpDaemon
  module API
    class Jobs < Grape::API

      ### ENDPOINTS
      desc "Read job with ID"
      params do
        requires :id, type: String, desc: "ID of the Job to read"
      end
      get "/:id", requirements: { id: /.*/ } do
        begin
          # Get job to display
          raise RestFtpDaemon::JobNotFound if params[:id].nil?
          job = RestFtpDaemon::JobQueue.instance.find_by_id(params[:id]) || RestFtpDaemon::JobQueue.instance.find_by_id(params[:id], true)
          raise RestFtpDaemon::JobNotFound if job.nil?

        rescue RestFtpDaemon::JobNotFound => exception
          log_error "JobNotFound: #{exception.message}"
          error!({ error: :api_job_not_found, message: exception.message }, 404)

        rescue StandardError => exception
          log_error "Exception: #{exception.message}"
          error!({ error: :api_exception, message: exception.message }, 500)

        else
          status 200
          present job, with: RestFtpDaemon::API::Entities::Job, type: "complete"

        end
      end

      desc "List all Jobs"
      get "/" do
        begin
          # Get jobs to display
          jobs = RestFtpDaemon::JobQueue.instance.jobs

        rescue StandardError => exception
          log_error "Exception: #{exception.message}"
          error!({ error: :api_exception, message: exception.message }, 500)

        else
          status 200
          present jobs, with: RestFtpDaemon::API::Entities::Job

        end
      end

      desc "Create a new job"
      params do
        requires :source, type: String, desc: "Source file pattern"
        requires :target, type: String, desc: "Target remote path"

        optional :label, type: String, desc: "Descriptive label for this job"
        optional :notify, type: String, desc: "URL to get POST'ed notifications back"
        optional :priority, type: Integer, desc: "Priority level of the job (lower is stronger)"
        optional :pool, type: String, desc: "Pool of worker to be used"
        optional :type,
          type: String,
          desc: "Type of job",
          default: JOB_TYPE_TRANSFER,
          values: {value: JOB_TYPES, message: "should be one of: #{JOB_TYPES.join', '}"},
          allow_blank: { value: false, message: 'cannot be empty' }
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
          log_error "RestFtpDaemonException: #{exception.message}"
          error!({error: :api_exception, message: exception.message}, 500)

        else
          status 201
          present job, with: RestFtpDaemon::API::Entities::Job, hide_params: true

        end
      end

    end
  end
end
