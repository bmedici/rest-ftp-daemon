module RestFtpDaemon
  module API
    class Root < Grape::API


####### DASHBOARD - GET /

      # Server global status
      get '/' do
        info "GET /"

        # Initialize Facter
        Facter.loadfacts


        # Jobs to display
        popped_jobs = $queue.ordered_popped.reverse
        @jobs_queued = $queue.ordered_queue.reverse

        if params["only"].nil? || params["only"].blank?
          @only = nil
        else
          @only = params["only"].to_sym
        end

        case @only
        when nil
          @jobs_current = popped_jobs
        when JOB_STATUS_QUEUED
          @jobs_current = @jobs_queued
        else
          @jobs_current = $queue.popped_reverse_sorted_by_status @only
        end

        # Count jobs for each status and total
        @counts = $queue.counts_by_status
        @count_all = $queue.all_size

        # Get workers status
        @worker_vars = $pool.worker_vars

        # Compile haml template
        output = render :dashboard, {jobs: jobs, only: only}

        # Send response
        env['api.format'] = :html
        format "html"
        status 200
        content_type "text/html"
        body output
      end

    end
  end
end
