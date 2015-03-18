module RestFtpDaemon
  module API
    class Root < Grape::API


####### DASHBOARD - GET /

      # Server global status
      get '/' do
        info "GET /"

        # Initialize Facter
        Facter.loadfacts

        # Detect QS filters
        only = params["only"].to_s

        # Get jobs to display
        jobs = $queue.sorted_by_status(only)

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
