require "grape"
require "haml"
require "sys/cpu"
require "facter"

module RestFtpDaemon
  module API
    class Dashbaord < Grape::API

####### HELPERS

      helpers do

        def logger
          Root.logger
        end

        def render name, values={}
          template = File.read("#{APP_LIBS}/views/#{name}.haml")
          haml_engine = Haml::Engine.new(template)
          haml_engine.render(binding, values)
        end

      end


####### DASHBOARD - GET /

      # Server global status
      get "/" do
        log_info "GET /"

        # Initialize Facter
        Facter.loadfacts

        # Detect QS filters
        @only = params["only"].to_s

        # Get jobs for this view, order jobs by their weights
        result = $queue.filter_jobs(@only).reverse

        # Provide queue only if no filtering set
        @queue = []
        @queue = $queue.queue.reverse if @only.empty?

        # Get workers status
        @worker_variables = $pool.worker_variables

        # Build paginator
        @paginate = Paginate.new result
        @paginate.only = params["only"]
        @paginate.page = params["page"]

        # Compile haml template
        output = render :dashboard

        # Send response
        env["api.format"] = :html
        format "html"
        status 200
        content_type "text/html"
        body output
      end

    end
  end
end
