require "grape"
require 'grape-swagger'

module RestFtpDaemon
  module API
    class Root < Grape::API

    add_swagger_documentation hide_documentation_path: true,
      mount_path: '/swagger.json'

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
