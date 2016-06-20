module RestFtpDaemon
  module API
    class Debug < Grape::API

      ### ENDPOINTS
      desc "Show app routes, params encodings"
      get "/" do
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

       # Build response
       return  {
          routes: RestFtpDaemon::API::Root.routes,
          encodings: encodings,
          }
      end

    end
  end
end
