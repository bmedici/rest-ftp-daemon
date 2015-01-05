module RestFtpDaemon
  module API
    class Root < Grape::API


####### GET /jobs/:id

      params do
        requires :id, type: String, desc: 'ID of the Job to read', regexp: /[^\/]+/
      end
      get '/jobs/*id' do
        info "GET /jobs/#{params[:id]}"
        begin
          job = job_find params[:id]
          raise RestFtpDaemon::JobNotFound if job.nil?

        rescue RestFtpDaemon::JobNotFound => exception
          status 404
          api_error exception
        rescue RestFtpDaemonException => exception
          status 500
          api_error exception
        rescue Exception => exception
          status 501
          api_error exception
        else
          status 200
          present job, :with => RestFtpDaemon::API::Entities::JobPresenter, type: "complete"
        end

      end


####### GET /jobs/

      desc "List all Jobs"

      get '/jobs/' do
        info "GET /jobs"
        begin
          jobs = $queue.all
        rescue RestFtpDaemonException => exception
          status 501
          api_error exception
        rescue Exception => exception
          status 501
          api_error exception
        else
          status 200
          present jobs, :with => RestFtpDaemon::API::Entities::JobPresenter
        end
      end



####### POST /jobs/

      desc "Create a new job"

      params do
        requires :source, type: String, desc: "Source file pattern"
        requires :target, type: String, desc: "Target remote path"
        optional :label, type: String, desc: "Descriptive label for this job"
        optional :notify, type: String, desc: "URL to get POST'ed notifications back"
        optional :priority, type: Integer, desc: "Priority level of the job (lower is stronger)"

        optional :overwrite, type: Boolean, desc: "overwrites files at target server",
          default: Settings.transfer[:overwrite]
        optional :mkdir, type: Boolean, desc: "create missing directories on target server",
          default: Settings.transfer[:mkdir]
        optional :tempfile, type: Boolean, desc: "upload to a temp file before renaming it to the target filename",
          default: Settings.transfer[:tempfile]
      end

      post '/jobs/' do
        info "POST /jobs #{params.inspect}"
        # request.body.rewind
        begin

          # Create a new job
          job_id = $queue.generate_id
          job = Job.new(job_id, params)

          # And push it to the queue
          $queue.push job

          # Increment a counter
          $queue.counter_inc :jobs_received

        rescue JSON::ParserError => exception
          status 406
          api_error exception
        rescue RestFtpDaemonException => exception
          status 412
          api_error exception
        rescue Exception => exception
          status 501
          api_error exception
        else
          status 201
          present job, :with => RestFtpDaemon::API::Entities::JobPresenter
        end
      end

    end
  end
end
