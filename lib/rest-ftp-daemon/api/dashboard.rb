module RestFtpDaemon
  module API

    class Root < Grape::API

####### DASHBOARD - GET /

      # Server global status
      get '/' do
        info "GET /"

        # Initialize UsageWatch
        Facter.loadfacts
        @info_load = Sys::CPU.load_avg.first.to_f
        @info_procs = (Facter.value :processorcount).to_i
        @info_ipaddr = Facter.value(:ipaddress)
        @info_memfree = Facter.value(:memoryfree)

        # Compute normalized load
        if @info_procs.zero?
          @info_norm = "N/A"
        else
          @info_norm = (100 * @info_load / @info_procs).round(1)
        end

        # Jobs to display
        popped_jobs = $queue.ordered_popped.reverse
        @jobs_queued = $queue.ordered_queue.reverse

        if params["only"].nil? || params["only"].blank?
          @only = nil
        else
          @only = params["only"].to_sym
        end

        if @only.nil?
          @jobs_popped = popped_jobs
        else
          @jobs_popped = $queue.popped_reverse_sorted_by_status @only
        end

        # Count jobs for each status
        @counts = $queue.popped_counts_by_status

        # Get workers status
        @gworker_statuses = $pool.get_worker_statuses

        # Compile haml template
        output = render :dashboard

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
