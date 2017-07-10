require "haml"
require "sys/cpu"
require "get_process_mem"
require "facter"
require "grape"

module RestFtpDaemon
  module API
    class Dashboard < Grape::API
      include BmcDaemonLib
      content_type :html, 'application/html'
      format :html

      ### HELPERS
      helpers do
        def log_context
          {caller: "API::Dashboard"}
        end

        def render name, values={}
          # Prepare template engine
          template = File.read("#{Conf.app_libs}/views/#{name}.haml")
          haml_engine = Haml::Engine.new(template, encoding: Encoding::UTF_8)

          # Inject helpers
          scope_object = eval("self", binding)
          scope_object.extend RestFtpDaemon::ViewsHelper
          scope_object.extend RestFtpDaemon::CommonHelpers

          # Do the rendering !
          haml_engine.render(scope_object, values)
        end

        def build_dashboard filter = ''
          # Initialize Facter
          begin
            Facter.loadfacts
          rescue StandardError => exception
            log_error "dashboard/build: #{exception.inspect}"
          end

          # Detect QS filters
          @filter = filter.to_s
          @page = params["page"].to_i

          # Get jobs for this view, order jobs by their weights
          jobs_with_status = RestFtpDaemon::JobQueue.instance.jobs_with_status(filter).reverse

          # Provide queue only if no filtering set
          if filter.empty?
            @jobs_queued = RestFtpDaemon::JobQueue.instance.jobs_queued
          else
            @jobs_queued = []
          end

          # Build paginator
          @paginate = Paginate.new jobs_with_status
          @paginate.filter = filter
          @paginate.page = @page
          @paginate.all = params.keys.include? "all"

          # Compile haml template
          output = render :dashboard

          # Send response
          #env["api.format"] = :html
          # format "html"
          status 200
          content_type "html"
          body output
        end

      end

      ### DASHBOARD
      desc "Show the main dashboard", tags: ['status']
      get "/" do
        build_dashboard()
      end

      desc "Dashboard filtered", hidden: true

      params do
        optional :filter, type: String, desc: "Filter for the jobs list"#, regexp: /[^\/]+/
      end
      get ":filter" do
        build_dashboard(params["filter"])
      end

    end
  end
end