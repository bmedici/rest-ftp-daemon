class RestFtpDaemon < Sinatra::Base

  # General config
  configure :development, :production do

    # Create new thread group
    @@threads = ThreadGroup.new
    #set :dummy, true
    set :sessions, false
    # set :logging, true
    # set :root, APP_ROOT + '/lib/'
  end

  # Server initialization
  def initialize
    # Setup logger
    @logger = Logger.new(APP_ROOT + '/main.log','daily')
    @logger.level = Logger::INFO

    # Other stuff
    @@last_worker_id = 0
    @@hostname = `hostname`.chomp

    super
  end

  # Server global status
  get "/" do
    content_type :json
    JSON.pretty_generate get_status
  end

  # List jobs
  get "/jobs" do
    # Build response
    content_type :json
    JSON.pretty_generate get_jobs
    #@@threads.count
  end

  # List jobs
  delete "/jobs/:name" do
    # Kill this job
    ret = delete_job params[:name]

    # Fail if no process has been killed
    error 404 if ret<1

    # Build response
    content_type :json
    JSON.pretty_generate nil
  end

  # Spawn a new thread for this new job
  post '/jobs' do
    request.body.rewind
    payload = JSON.parse request.body.read
    info "POST / with #{payload.to_json}"

    # Spawn a thread
    #config = {}
    result = new_job payload

    # Build response
    content_type :json
    JSON.pretty_generate result
  end

  protected

  def process_job
    # Init
    info "process_job: starting"
    context = Thread.current[:context]
    transferred = 0

    # Check source
    job_source = File.expand_path(context["source"])
    if !(File.exists? job_source)
      job_status ERR_JOB_SOURCE_NOTFOUND, :ERR_JOB_SOURCE_NOTFOUND
      return
    end
    info "process_job: job_source: #{job_source}"
    source_size = File.size job_source

    # Check target
    job_target = context["target"]
    target = URI(job_target) rescue nil
    if job_target.nil? || target.nil?
      job_status ERR_JOB_TARGET_UNPARSEABLE, :ERR_JOB_TARGET_UNPARSEABLE
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
    Thread.current[:status] = :transferring
    job_status ERR_BUSY, :running
    job_set :source_size, source_size

    begin
      ftp.putbinaryfile(job_source, target_name, TRANSFER_CHUNK_SIZE) do |block|
        # Update thread info
        percent = (100.0 * transferred / source_size).round(1)
        info "transferring [#{percent} %] of [#{target_name}]"
        job_set :progress, percent
        job_set :transferred, transferred

        # Update counters
        transferred += TRANSFER_CHUNK_SIZE
      end

    rescue Net::FTPPermError
      Thread.current[:status] = :failed
      job_status ERR_JOB_PERMISSION, :ERR_JOB_PERMISSION
      info "source: FAILED: PERMISSIONS ERROR"

    else
      Thread.current[:status] = :finished
      job_status ERR_OK, :finished
      info "source: finished stransfer"
    end

    ftp.close
  end

  def get_status
    {
    app_name: APP_NAME,
    hostname: @@hostname,
    version: APP_VER,
    started: APP_STARTED,
    uptime: (Time.now - APP_STARTED).round(1),
    jobs_count: @@threads.list.count,
    }
  end

  def get_jobs
    output = []
    @@threads.list.each do |thread|
      output << {
      :id => thread[:name],
      :process => thread.status,
      :status =>  thread[:status],
      :context => thread[:context],
      }
    end
    output
  end


  def delete_job name
    count = 0
    @@threads.list.collect do |thread|
      next unless thread[:name] == name
      Thread.kill(thread)
      count += 1
    end
    count
  end

  def new_job context = {}
    info "new_job: creating thread"

    # Generate name
    @@last_worker_id +=1
    host = @@hostname.split('.')[0]
    name = "#{host}-#{Process.pid.to_s}-#{@@last_worker_id}"
    info "new_job: creating thread [#{name}]"

    # Parse parameters
    job_source = context["source"]
    job_target = context["target"]
    return { code: ERR_REQ_SOURCE_MISSING, errmsg: :ERR_REQ_SOURCE_MISSING} if job_source.nil?
    return { code: ERR_REQ_TARGET_MISSING, errmsg: :ERR_REQ_TARGET_MISSING} if job_target.nil?
    #return { code: ERR_TRX_SOURCE_FILE_NOT_FOUND, errmsg: "ERR_TRX_SOURCE_FILE_NOT_FOUND [#{job_source}]"} unless File.exists? job_source

    # Parse dest URI
    target = URI(job_target)
    info target.scheme
    return { code: ERR_REQ_TARGET_SCHEME, errmsg: :ERR_REQ_TARGET_SCHEME} unless target.scheme == "ftp"

    # Create thread
    job = Thread.new(name, job) do
      # Initialize context
      Thread.current[:name] = name
      Thread.current[:created] = Time.now.to_f;
      Thread.current[:status] = :thread_initializing

      # Store job info
      Thread.current[:context] = context
      job_status ERR_BUSY, :thread_initializing
      Thread.abort_on_exception = true

      # Do the job
      info "new_job: thread running"
      process_job

      # Sleep a few seconds before dying
      Thread.current[:status] = :thread_ending
      sleep THREAD_SLEEP_BEFORE_DIE
      info "new_job: thread finished"
    end

    # Keep thread in thread group
    info "new_job: attaching thread [#{name}] to group"
    @@threads.add job

    return { code: 0, errmsg: 'success', name: name, context: context }
  end

  def log level, msg=""
    @logger.send(level.to_s, msg)
  end

  def info msg=""
    log :info, msg
  end

  def job_status code, errmsg
    Thread.current[:context] ||= {}
    Thread.current[:context][:code] = code
    Thread.current[:context][:errmsg] = errmsg
  end

  def job_set attribute, value
    Thread.current[:context] ||= {}
    Thread.current[:context][attribute] = value
  end


end
