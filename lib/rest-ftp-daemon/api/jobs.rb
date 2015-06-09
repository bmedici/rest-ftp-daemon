module RestFtpDaemon
  module API
    class Root < Grape::API


####### GET /jobs/:id

      params do
        requires :id, type: String, desc: 'ID of the Job to read', regexp: /[^\/]+/
      end
      get '/jobs/*id' do
        log_info 'GET /jobs/#{params[:id]}'

        begin
          # Get job to display
          raise RestFtpDaemon::JobNotFound if params[:id].nil?
          job = $queue.find_by_id(params[:id]) || $queue.find_by_id(params[:id], true)
          raise RestFtpDaemon::JobNotFound if job.nil?

        rescue RestFtpDaemon::JobNotFound => exception
          log_error "JobNotFound: #{exception.message}"
          status 404
          api_error exception
        rescue RestFtpDaemonException => exception
          log_error "RestFtpDaemonException: #{exception.message}"
          status 500
          api_error exception
        rescue StandardError => exception
          log_error "Exception: #{exception.message}"
          status 501
          api_error exception
        else
          status 200
          present job, :with => RestFtpDaemon::API::Entities::JobPresenter, type: 'complete'
        end

      end


####### GET /jobs/

      desc 'List all Jobs'

      get '/jobs/' do
        log_info 'GET /jobs'

        begin
          # Detect QS filters
          only = params['only'].to_s

          # Get jobs to display
          # jobs = $queue.sorted_by_status(only)
          jobs = $queue.jobs

        rescue RestFtpDaemonException => exception
          log_error "RestFtpDaemonException: #{exception.message}"
          status 501
          api_error exception
        rescue StandardError => exception
          log_error "Exception: #{exception.message}"
          status 501
          api_error exception
        else
          status 200
          present jobs, :with => RestFtpDaemon::API::Entities::JobPresenter
        end
      end



####### POST /jobs/

      desc 'Create a new job'

      params do
        requires :source, type: String, desc: 'Source file pattern'
        requires :target, type: String, desc: 'Target remote path'
        optional :label, type: String, desc: 'Descriptive label for this job'
        optional :notify, type: String, desc: 'URL to get POST\'ed notifications back'
        optional :priority, type: Integer, desc: 'Priority level of the job (lower is stronger)'

        optional :overwrite, type: Boolean, desc: 'Overwrites files at target server',
          default: Settings.transfer[:overwrite]
        optional :mkdir, type: Boolean, desc: 'Create missing directories on target server',
          default: Settings.transfer[:mkdir]
        optional :tempfile, type: Boolean, desc: 'Upload to a temp file before renaming it to the target filename',
          default: Settings.transfer[:tempfile]
      end

      post '/jobs/' do
        log_info 'POST /jobs', params

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
          status 406
          api_error exception
        rescue RestFtpDaemonException => exception
          log_error "RestFtpDaemonException: #{exception.message}"
          status 412
          api_error exception
        rescue StandardError => exception
          log_error "Exception: #{exception.message}"
          status 501
          api_error exception
        else
          status 201
          present job, :with => RestFtpDaemon::API::Entities::JobPresenter, hide_params: true
        end
      end

    end
  end
end
