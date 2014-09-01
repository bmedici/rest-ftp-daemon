module RestFtpDaemon

  class API < Grape::API
    version 'v1', using: :header, vendor: 'ftven'
    format :json


    ######################################################################
    ####### INIT
    ######################################################################
    def initialize
      # Setup logger
      @@logger = Logger.new(APP_LOGTO, 'daily')
      # @@queue = Queue.new

      # Create new thread group
      @@threads = ThreadGroup.new

      # Other stuff
      @@last_worker_id = 0
      super
    end

    ######################################################################
    ####### HELPERS
    ######################################################################
    helpers do
      def api_error exception
        {
        :error => exception.class,
        :errmsg => exception.message,
        :backtrace => exception.backtrace.first,
        #:backtrace => exception.backtrace,
        }
      end

      def info msg=""
        @@logger.info msg
      end

      def threads_with_id job_id
        @@threads.list.select do |thread|
          next unless thread[:job].is_a? Job
          thread[:job].get(:id) == job_id
        end
      end

      def job_describe job_id
        # Find threads with tihs id
        threads = threads_with_id job_id
        raise RestFtpDaemon::JobNotFound if threads.empty?

        # Find first job with tihs id
        job = threads.first[:job]
        raise RestFtpDaemon::JobNotFound unless job.is_a? Job
        description = job.describe

        # Return job description
        description
      end

      def job_delete job_id
        # Find threads with tihs id
        threads = threads_with_id job_id
        raise RestFtpDaemon::JobNotFound if threads.empty?

        # Get description just before terminating the job
        job = threads.first[:job]
        raise RestFtpDaemon::JobNotFound unless job.is_a? Job
        description = job.describe

        # Kill those threads
        threads.each do |t|
          Thread.kill(t)
        end

        # Return job description
        description
      end

      def job_list
        @@threads.list.map do |thread|
          next unless thread[:job].is_a? Job
          thread[:job].describe
        end
      end

    end


    ######################################################################
    ####### API DEFINITION
    ######################################################################

    # Server global status
    get '/' do
      info "GET /"

      status 200
      {
        app_name: APP_NAME,
        hostname: `hostname`.chomp,
        version: RestFtpDaemon::VERSION,
        started: APP_STARTED,
        uptime: (Time.now - APP_STARTED).round(1),
      }
    end

    # Server test
    get '/test' do
      info "GET /tests"
      begin
        raise RestFtpDaemon::DummyException
      rescue RestFtpDaemon::RestFtpDaemonException => exception
        status 501
        api_error exception
      rescue Exception => exception
        status 501
        api_error exception
      else
        status 200
        {}
      end
    end

    # List jobs
    get "/jobs" do
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

    # Get job info
    get "/jobs/:id" do
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
    delete "/jobs/:id" do
     info "DELETE /jobs/#{params[:name]}"
      begin
        response = job_delete params[:id].to_i
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

    # Spawn a new thread for this new job
    post '/jobs' do
      info "POST /jobs: #{request.body.read}"
      begin
        # Extract params
        request.body.rewind
        params = JSON.parse request.body.read

        # Create a new job
        job_id = @@last_worker_id += 1
        job = Job.new(job_id, params)

        # Put it inside a thread
        th = Thread.new(job) do |thread|
          # Tnitialize thread
          Thread.abort_on_exception = true
          Thread.current[:job] = job

          # Do the job
          job.process

          # Wait for a few seconds before cleaning up the job
          job.wander RestFtpDaemon::THREAD_SLEEP_BEFORE_DIE
        end

        # Stack it to the pool
        #@@queue << job
        @@threads.add th

        # And start it asynchronously
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

  end

end
