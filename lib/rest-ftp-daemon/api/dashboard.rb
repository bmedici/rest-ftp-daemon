require "haml"
require "sys/cpu"
require "get_process_mem"
require "facter"

module RestFtpDaemon
  module API

    class Dashbaord < Grape::API

      ### HELPERS

      helpers do
        def render name, values={}
          template = File.read("#{Conf.app_libs}/views/#{name}.haml")

          haml_engine = Haml::Engine.new(template, encoding: Encoding::UTF_8)
              #:encoding => Encoding::ASCII_8BIT
          haml_engine.render(binding, values)
        end

        def build_dashboard filter = ''
          # Initialize Facter
          Facter.loadfacts

          # Detect QS filters
          @filter = filter.to_s
          @page = params["page"].to_i

          # Get jobs for this view, order jobs by their weights
          jobs_with_status = $queue.jobs_with_status(filter).reverse

          # Provide queue only if no filtering set
          if filter.empty?
            @jobs_queued = $queue.jobs_queued
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
          env["api.format"] = :html
          format "html"
          status 200
          content_type "text/html"
          body output
        end

      end


      ### DASHBOARD
      desc "Show a global dashboard"
      get "/" do
        build_dashboard()
      end

      params do
        optional :filter, type: String, desc: "Filter for the jobs list"#, regexp: /[^\/]+/
      end
      get ":filter" do
        build_dashboard(params["filter"])
      end

    end
  end
end
