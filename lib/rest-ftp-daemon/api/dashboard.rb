module RestFtpDaemon
  module API
    class Root < Grape::API


####### HELPERS

      helpers do
      end


####### DASHBOARD - GET /

      # Server global status
      get '/' do
        info "GET /"

        # Initialize Facter
        Facter.loadfacts

        # Detect QS filters
        only = params["only"].to_s

        # Get jobs for this view, order jobs by their weights
        current = $queue.filter_jobs only

        # Provide queue only if no filtering set
        queue = []
        queue = $queue.queue if only.empty?

        # Get workers status
        @worker_vars = $pool.worker_vars

        # Compile haml template
        output = render :dashboard, {queue: queue, current: current, only: only}

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
