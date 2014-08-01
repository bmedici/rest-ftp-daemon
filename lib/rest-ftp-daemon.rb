class RestFtpDaemon < Sinatra::Base

  # General config
  configure :development, :production do

    # Create new thread group
    @@workers = ThreadGroup.new

    # Logging configuration
    #use Rack::CommonLogger, logger

    # Some other configuration
    disable :sessions
    disable :logging
  end

  # Server initialization
  def initialize
    # Setup logger
    @logger = Logger.new(APP_LOGTO, 'daily')
    #@logger = Logger.new
    #@logger.level = Logger::INFO

    # Other stuff
    @@last_worker_id = 0
    @@hostname = `hostname`.chomp

    super
  end

  # Server global status
  get "/" do
    # Debug query
    info "GET /"

    # Build response
    content_type :json
    JSON.pretty_generate get_status
  end

  # List jobs
  get "/jobs" do
    # Debug query
    info "GET /jobs"

    # Build response
    content_type :json
    JSON.pretty_generate get_jobs
  end

  # Get job info
  get "/jobs/:id" do
    # Debug query
    info "GET /jobs/#{params[:id]}"

    # Find this process by name
    found = find_job params[:id]

    # Build response
    error 404 and return if found.nil?
    content_type :json
    JSON.pretty_generate found
  end

  # Delete jobs
  delete "/jobs/:id" do
    # Debug query
    info "DELETE /jobs/#{params[:name]}"

    # Find and kill this job
    found = delete_job params[:id]

    # Build response
    error 404 and return if found.nil?
    content_type :json
    JSON.pretty_generate found
  end

  # Spawn a new thread for this new job
  post '/jobs' do
    # Extract payload
    request.body.rewind
    payload = JSON.parse request.body.read

    # Debug query
    info "POST /jobs: #{payload.to_json}"

    # Spawn a thread for this job
    result = new_job payload

    # Build response
    content_type :json
    JSON.pretty_generate result
  end

  protected

  def process_job
    # Init
    info "process_job: starting"
    job = Thread.current.job
    job_status :started
    transferred = 0

    # Check source
    job_source = File.expand_path(job["source"])
    if !(File.exists? job_source)
      job_error ERR_JOB_SOURCE_NOTFOUND, :ERR_JOB_SOURCE_NOTFOUND
      return
    end
    info "process_job: job_source: #{job_source}"
    source_size = File.size job_source
    job_set :source_size, source_size

    # Check target
    job_target = job["target"]
    target = URI(job_target) rescue nil
    if job_target.nil? || target.nil?
      job_error ERR_JOB_TARGET_UNPARSEABLE, :ERR_JOB_TARGET_UNPARSEABLE
      return
    end
    info "process_job: job_target: #{job_target}"

    # Split URI
    target_path = File.dirname target.path
    target_name = File.basename target.path
    info "ftp_transfer: job_target.host [#{target.host}]"
    info "ftp_transfer: target_path [#{target_path}]"
    info "ftp_transfer: target_name [#{target_name}]"

    # Prepare FTP transfer
    ftp = Net::FTP.new(target.host)
    ftp.passive = true
    ftp.login
    ftp.chdir(target_path)

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

    ftp.close
  end

  def get_status
    info "> get_status"
    {
    app_name: APP_NAME,
    hostname: @@hostname,
    version: APP_VER,
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

    # Keep thread in thread group
    info "new_job: attaching thread [#{worker_name}] to group"
    @@workers.add job

    return { code: 0, errmsg: 'success', worker_id: worker_id, context: context }
  end

  def info msg=""
    @logger.info msg
  end

  def job_error error, errmsg = nil
    job_set :error, error
    job_set :errmsg, errmsg
  end
  def job_status status
    job_set :status, status
  end

  def job_set attribute, value, thread = Thread.current
    thread[:job][attribute] = value if thread[:job].is_a? Enumerable
  end


end
