require "grape"

module RestFtpDaemon
  module API
    class Jobs < Grape::API

      ### HELPERS

      helpers do
        def logger
          Root.logger
        end
      end


      ### Common request logging
      before do
        log_info "HTTP #{request.request_method} #{request.fullpath}", params
      end


      ### READ ONE JOB

      desc "Read job with ID"
      params do
        requires :id, type: String, desc: "ID of the Job to read"
      end
      get "/:id", requirements: { id: /.*/ } do
        begin
          # Get job to display
          raise RestFtpDaemon::JobNotFound if params[:id].nil?
          job = $queue.find_by_id(params[:id]) || $queue.find_by_id(params[:id], true)
          raise RestFtpDaemon::JobNotFound if job.nil?

        rescue RestFtpDaemon::JobNotFound => exception
          log_error "JobNotFound: #{exception.message}"
          error!({ error: :api_job_not_found, message: exception.message }, 404)

        rescue StandardError => exception
          log_error "Exception: #{exception.message}"
          error!({ error: :api_exception, message: exception.message }, 500)

        else
          status 200
          present job, with: RestFtpDaemon::API::Entities::JobPresenter, type: "complete"

        end
      end


      ### READ ALL JOBS

      desc "List all Jobs"
      get "/" do
        begin
          # Get jobs to display
          jobs = $queue.jobs

        rescue StandardError => exception
          log_error "Exception: #{exception.message}"
          error!({ error: :api_exception, message: exception.message }, 500)

        else
          status 200
          present jobs, with: RestFtpDaemon::API::Entities::JobPresenter

        end
      end


      ### CREATE A JOB

      desc "Create a new job"
      params do
        requires :source, type: String, desc: "Source file pattern"
        requires :target, type: String, desc: "Target remote path"
        optional :label, type: String, desc: "Descriptive label for this job"
        optional :notify, type: String, desc: "URL to get POST'ed notifications back"
        optional :priority, type: Integer, desc: "Priority level of the job (lower is stronger)"
        optional :pool, type: String, desc: "Pool of worker to be used"
        optional :overwrite,
          type: Boolean,
          desc: "Overwrites files at target server",
          default: Settings.at(:transfer, :overwrite)
        optional :mkdir,
          type: Boolean,
          desc: "Create missing directories on target server",
          default: Settings.at(:transfer, :mkdir)
        optional :tempfile,
          type: Boolean,
          desc: "Upload to a temp file before renaming it to the target filename",
          default: Settings.at(:transfer, :tempfile)
      end
      post "/" do
        # log_debug params.to_json
        begin
          # Create a new job
          job_id = $queue.generate_id
          job = Job.new(job_id, params)

          # And push it to the queue
          $queue.push job

          # Increment a counter
          $queue.counter_inc :jobs_received

        rescue JSON::ParserError => exception
          log_error "JSON::ParserError: #{exception.message}"
          error!({error: :api_parse_error, message: exception.message}, 422)

        rescue RestFtpDaemonException => exception
          log_error "RestFtpDaemonException: #{exception.message}"
          error!({error: :api_exception, message: exception.message}, 500)

        else
          status 201
          present job, with: RestFtpDaemon::API::Entities::JobPresenter, hide_params: true

        end
      end

    end
  end
end
