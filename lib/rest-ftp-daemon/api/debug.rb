module RestFtpDaemon
  module API
    class Debug < Grape::API

      ### HELPERS
      helpers do

        def debug_metrics
          Metrics.sample
        end

        def debug_encodings
          # Encodings
          encodings = {}
          jobs = $queue.jobs

          jobs.each do |job|
            # here = out[job.id] = {}
            me = encodings[job.id] = {}

            me[:error] = job.error.encoding.to_s unless job.error.nil?
            me[:status] = job.status.encoding.to_s unless job.status.nil?

            Job::FIELDS.each do |name|
              value = job.send(name)
              me[name] = value.encoding.to_s if value.is_a? String
            end

            job.infos.each do |name, value|
              me["infos_#{name}"] = value.encoding.to_s if value.is_a? String
            end
          end
        end

      end

      ### ENDPOINTS
      desc "debug"
      get "/" do
       # Build response
       return  {
          metrics: debug_metrics,
          routes: RestFtpDaemon::API::Root.routes,
          encodings: debug_encodings,
          }
      end

    end
  end
end
