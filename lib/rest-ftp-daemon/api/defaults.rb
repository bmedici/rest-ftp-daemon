# encoding: UTF-8
require 'grape'
SIZE_UNITS = ["B", "KB", "MB", "GB", "TB", "PB" ]


module RestFtpDaemon
  module API
    module Defaults
      extend ActiveSupport::Concern

      included do
        #version 'v1', using: :header, vendor: 'ftven'
        format :json
        do_not_route_head!
        do_not_route_options!

        # before do
        #   header['Access-Control-Allow-Origin'] = '*'
        #   header['Access-Control-Request-Method'] = '*'
        # end

        # Handle authentication
        # http_basic do |username, password|
        #   User.authenticate!(username, password)
        # end

        # # global handler for simple not found case
        # rescue_from ActiveRecord::RecordNotFound do |e|
        #   error_response(message: e.message, status: 404)
        # end

        # # global exception handler, used for error notifications
        # rescue_from :all do |e|
        #   if Rails.env.development?
        #     raise e
        #   else
        #     Raven.capture_exception(e)
        #     error_response(message: "Internal server error", status: 500)
        #   end
        # end

        # # HTTP header based authentication
        # before do
        #   error!('Unauthorized', 401) unless headers['Authorization'] == "some token"
        # end

        helpers do
          def format_nice_bytes( number )
            return "Ø" if number.nil? || number.zero?
            index = ( Math.log( number ) / Math.log( 2 ) ).to_i / 10
            converted = number.to_i / ( 1024 ** index )
            "#{converted} #{SIZE_UNITS[index]}"
          end
          def api_error exception
            {
            :error => exception.class,
            :errmsg => exception.message,
            :backtrace => exception.backtrace.first,
            #:backtrace => exception.backtrace,
            }
          end
        end

      end


    end
  end
end
