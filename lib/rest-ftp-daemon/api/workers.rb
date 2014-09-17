# module RestFtpDaemon
#   module API

#     class Workers < Grape::API
#       include RestFtpDaemon::API::Defaults
#       logger ActiveSupport::Logger.new Settings.logs.api, 'daily' unless Settings.logs.api.nil?

#       helpers do
#         def info message, level = 0
#           Jobs.logger.add(Logger::INFO, "#{'  '*level} #{message}", "API::Workers")
#         end

#         def worker_list
#           return {
#             busy: $pool.busy_size,
#             idle: $pool.idle_size,
#             to_s: $pool.to_s,
#             }
#           #return $workers.list.size
#           $workers.list.map do |thread|
#             #next unless thread[:job].is_a? Worker
#             "worker"
#             #thread[:worker].inspect
#           end
#         end

#       end

#       # List jobs
#       desc "Get a list of workers"
#       get do
#         info "GET /workers"
#         begin
#           response = worker_list
#         rescue RestFtpDaemonException => exception
#           status 501
#           api_error exception
#         rescue Exception => exception
#           status 501
#           api_error exception
#         else
#           status 200
#           response
#         end
#       end

#     end
#   end
# end
