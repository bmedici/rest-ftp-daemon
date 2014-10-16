module RestFtpDaemon
  module API

    class Jobs < Grape::API


####### CLASS CONFIG

      #include RestFtpDaemon::API::Defaults
      #logger ActiveSupport::Logger.new Settings.logs.api, 'daily' unless Settings.logs.api.nil?

      params do
        optional :overwrite, type: Integer, default: false
      end


####### INITIALIZATION

      def initialize
        $last_worker_id = 0

        # Check that Queue and Pool are available
        raise RestFtpDaemon::MissingQueue unless defined? $queue
        raise RestFtpDaemon::MissingQueue unless defined? $pool

        super
      end


####### HELPERS

      helpers do

        def threads_with_id job_id
          $threads.list.select do |thread|
            next unless thread[:job].is_a? Job
            thread[:job].id == job_id
          end
        end

        def job_describe job_id
          raise RestFtpDaemon::JobNotFound if ($queue.queued_size==0 && $queue.popped_size==0)

          # Find job with this id
          found = $queue.all.select { |job| job.id == job_id }.first
          raise RestFtpDaemon::JobNotFound if found.nil?
          raise RestFtpDaemon::JobNotFound unless found.is_a? Job

          # Return job description
          found.describe
        end

        # def job_delete job_id
        # end

        def job_list
          $queue.all.map do |item|
            next unless item.is_a? Job
            item.describe
          end
        end

      end


####### API DEFINITION

      desc "Get information about a specific job"
      params do
        requires :id, type: Integer, desc: "job id"
      end
      get ':id' do
        info "GET /jobs/#{params[:id]}"
        begin
          response = job_describe params[:id].to_i
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
          response
        end
      end

      # Delete jobs
      desc "Kill and remove a specific job"
      delete ':id' do
       info "DELETE /jobs/#{params[:name]}"
       status 501
        # begin
        #   response = job_delete params[:id].to_i
        # rescue RestFtpDaemon::JobNotFound => exception
        #   status 404
        #   api_error exception
        # rescue RestFtpDaemonException => exception
        #   status 500
        #   api_error exception
        # rescue Exception => exception
        #   status 501
        #   api_error exception
        # else
        #   status 200
        #   response
        # end
      end

      # List jobs
      desc "Get a list of jobs"
      get do
        info "GET /jobs"
        begin
          response = job_list
        rescue RestFtpDaemonException => exception
          status 501
          api_error exception
        rescue Exception => exception
          status 501
          api_error exception
        else
          status 200
          response
        end
      end


      # Spawn a new thread for this new job
      desc "Create a new job"
      post do
        info "POST /jobs: #{request.body.read}"
        begin
          # Extract params
          request.body.rewind
          params = JSON.parse request.body.read

          # Create a new job
          job_id = $last_worker_id += 1
          job = Job.new(job_id, params)

          # And psuh it to the queue
          $queue.push job

          # Later: start it asynchronously
          #job.future.process

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
          job.describe
        end
      end

    protected

    def progname
      "API::Jobs"
    end

    end
  end
end
