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
        requires :source, type: String, desc: "source pattern"
        requires :target, type: String, desc: "target path"
        optional :notify, type: String, desc: ""
        optional :priority, type: Integer, desc: ""
        optional :overwrite, type: Boolean, desc: "wether to overwrites files at target server"
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
