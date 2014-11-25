module RestFtpDaemon
  module API

    class Jobs < Grape::API


####### CLASS CONFIG

      # params do
      #   optional :overwrite, type: Integer, default: false
      # end


####### INITIALIZATION

      def initialize
        #$last_worker_id = 0

        # Check that Queue and Pool are available
        raise RestFtpDaemon::MissingQueue unless defined? $queue
        raise RestFtpDaemon::MissingPool unless defined? $pool

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
          raise RestFtpDaemon::JobNotFound if ($queue.all_size==0)

          # Find job with exactly this id
          found = $queue.find_by_id(job_id)

          # Find job with this id while searching with the current prefix
          found = $queue.find_by_id(job_id, true) if found.nil?

          # Check that we did find it
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
        requires :id, type: String, desc: "job id", regexp:  /[^\/]+/
        # optional :audio do
        #   requires :format, type: Symbol, values: [:mp3, :wav, :aac, :ogg], default: :mp3
        # end
      end
      get '*id' do
        info "GET /jobs/#{params[:id]}"
        #return params
        begin
          response = job_describe params[:id]
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
        info "POST /jobs: #{params.inspect}"
        begin
          # Symbolize keys from params, and strip some fields
          symbolized = params.symbolize_keys
          symbolized.delete :route_info

          # Create a new job
          job_id = $queue.generate_id
          job = Job.new(job_id, symbolized)

          # And push it to the queue
          #$queue.push0 job
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
          job.describe
        end
      end

    protected

    # def progname
    #   "API::Jobs"
    # end

    end
  end
end
