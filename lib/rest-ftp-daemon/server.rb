module RestFtpDaemon

  class API < Grape::API
    version 'v1', using: :header, vendor: 'ftven'
    format :json


    # General config
    configure :development, :production do

      # Create new thread group



    end


    # Server initialization
    def initialize
      # Setup logger
      @logger = Logger.new(APP_LOGTO, 'daily')

      # Other stuff
      @@last_worker_id = 0
      @@hostname = `hostname`.chomp
      super
    end


    # Server test
      get "/test" do
        begin
          raise RestFtpDaemon::DummyException
        rescue RestFtpDaemon::RestFtpDaemonException => exception
          return api_error 501, exception
        else
          return api_success 200, ({success: true, reason: :dont_know_why})
        end
      end


    # Server global status
    get "/" do
      info "GET /"
      begin
        response = get_status
      rescue RestFtpDaemonException => exception
        return api_error 501, exception
      else
        return api_success 200, response
      end
    end


    # List jobs
    get "/jobs" do
      info "GET /jobs"
      begin
        response = get_jobs
      rescue RestFtpDaemonException => exception
        return api_error 501, exception
      else
        return api_success 200, response
      end
    end


    # Get job info
    get "/jobs/:id" do
      info "GET /jobs/#{params[:id]}"
      begin
        response = find_job params[:id]
      rescue RestFtpDaemon::JobNotFound => exception
        return api_error 404, exception
      rescue RestFtpDaemonException => exception
        return api_error 500, exception
      else
        return api_success 200, response
      end
    end


    # Delete jobs
    delete "/jobs/:id" do
     info "DELETE /jobs/#{params[:name]}"
      begin
        found = delete_job params[:id]
      rescue RestFtpDaemon::JobNotFound => exception
        return api_error 404, exception
      rescue RestFtpDaemonException => exception
        return api_error 500, exception
      else
        return api_success 200, found
      end
    end

    # Spawn a new thread for this new job
    post '/jobs' do
      info "POST /jobs: #{request.body.read}"
      begin
        # Extract payload
        request.body.rewind
        payload = JSON.parse request.body.read
        info "json payload: #{payload.to_json}"

        # Spawn a thread for this job
        result = enqueue_job payload

      rescue JSON::ParserError => exception
        return api_error 406, exception
      rescue RestFtpDaemonException => exception
        return api_error 412, exception
      else
        return api_success 201, result
      end
    end

    protected



       # Do transfer
      info "source: starting stransfer"
      #Thread.current[:status] = :transferring
      job_status :uploading
      job_error ERR_BUSY, :uploading

      begin
        ftp.putbinaryfile(job_source, target_name, TRANSFER_CHUNK_SIZE) do |block|
          # Update thread info
          percent = (100.0 * transferred / source_size).round(1)
          job_set :progress, percent
          job_set :transferred, transferred
          info "transferring [#{percent} %] of [#{target_name}]"

          # Update counters
          transferred += TRANSFER_CHUNK_SIZE
        end

      rescue Net::FTPPermError
        #job_status :failed
        job_error ERR_JOB_PERMISSION, :ERR_JOB_PERMISSION
        info "source: FAILED: PERMISSIONS ERROR"

      else
        #job_status :finished
        job_error ERR_OK, :finished
        info "source: finished stransfer"
      end

      # Close FTP connexion
      ftp.close
    end

    def get_status
      info "> get_status"
      {
      app_name: APP_NAME,
      hostname: @@hostname,
      version: RestFtpDaemon::VERSION,
      started: APP_STARTED,
      uptime: (Time.now - APP_STARTED).round(1),
      jobs_count: @@workers.list.count,
      }
    end

    def get_jobs
      info "> get_jobs"

      # Collect info's
      @@workers.list.map { |thread| thread.job }
    end

    def delete_job id
      info "> delete_job(#{id})"

      # Find jobs with this id
      jobs = jobs_with_id id

      # Kill them
      jobs.each{ |thread| Thread.kill(thread) }

      # Return the first one
      return nil if jobs.empty?
      jobs.first.job
    end

    def find_job id
      info "> find_job(#{id})"

      # Find jobs with this id
      jobs = jobs_with_id id

      # Return the first one
      return nil if jobs.empty?
      jobs.first.job
    end

    def jobs_with_id id
      info "> find_jobs_by_id(#{id})"
      @@workers.list.select{ |thread| thread[:id].to_s == id.to_s }
    end

    def new_job context = {}
      info "new_job"

      # Generate name
      @@last_worker_id +=1
      host = @@hostname.split('.')[0]
      worker_id = @@last_worker_id
      worker_name = "#{host}-#{Process.pid.to_s}-#{worker_id}"
      info "new_job: creating thread [#{worker_name}]"

      # Parse parameters
      job_source = context["source"]
      job_target = context["target"]
      return { code: ERR_REQ_SOURCE_MISSING, errmsg: :ERR_REQ_SOURCE_MISSING} if job_source.nil?
      return { code: ERR_REQ_TARGET_MISSING, errmsg: :ERR_REQ_TARGET_MISSING} if job_target.nil?

      # Parse dest URI
      target = URI(job_target)
      info target.scheme
      return { code: ERR_REQ_TARGET_SCHEME, errmsg: :ERR_REQ_TARGET_SCHEME} unless target.scheme == "ftp"

      # Create thread
      job = Thread.new(worker_id, worker_name, job) do
        # Tnitialize thread
        Thread.abort_on_exception = true
        job_status :initializing
        job_error ERR_OK

        # Initialize job info
        Thread.current[:job] = {}
        Thread.current[:job].merge! context if context.is_a? Enumerable
        Thread.current[:id] = worker_id
        job_set :worker_name, worker_name
        job_set :created, Time.now

        # Do the job
        info "new_job: thread running"
        process_job

        # Sleep a few seconds before dying
        job_status :graceful_ending
        sleep THREAD_SLEEP_BEFORE_DIE
        job_status :ended
        info "new_job: thread finished"
      end
    end


  end
end
