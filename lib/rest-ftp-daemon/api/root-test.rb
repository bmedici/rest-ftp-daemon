require "grape"
require 'grape-swagger'

module RestFtpDaemon
  module API
    class Root < Grape::API

      ### API Documentation
      add_swagger_documentation hide_documentation_path: true,
        api_version: Conf.app_ver,
        doc_version: Conf.app_ver,
        mount_path: MOUNT_SWAGGER_JSON,
        info: {
          title: Conf.app_name,
          version: Conf.app_ver,
          description: "API description for #{Conf.app_name} #{Conf.app_ver}",
          }


      namespace :hudson do
        desc 'Document root'
        get '/' do
        end
      end

      namespace :hudson do
        desc 'This gets something.',
          notes: '_test_'

        get '/simple' do
          { bla: 'something' }
        end
      end

      namespace :colorado do
        desc 'This gets something for URL using - separator.',
          notes: '_test_'

        get '/simple-test' do
          { bla: 'something' }
        end


      desc "List all Jobs", http_codes: [
        { code: 200, message: "Here are the jobs you requested" },
        ],
        is_array: true
      get "/" do
        begin
          # Get jobs to display
          jobs = RestFtpDaemon::JobQueue.instance.jobs

        rescue StandardError => exception
          log_error "Exception: #{exception.message}"
          error!({ error: :api_exception, message: exception.message }, 500)

        else
          status 200
          present jobs, with: RestFtpDaemon::API::Entities::Job

        end
      end


      end

    end
  end
end
