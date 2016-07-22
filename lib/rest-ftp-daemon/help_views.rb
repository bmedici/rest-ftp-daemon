module RestFtpDaemon
  module HelpViews

    def dashboard_job_url job
      "#{MOUNT_JOBS}/#{job.id}" if job.respond_to? :id
    end

  end
end
