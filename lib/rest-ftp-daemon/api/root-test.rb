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
      end

    end
  end
end
