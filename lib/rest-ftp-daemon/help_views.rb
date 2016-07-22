module RestFtpDaemon
  module HelpViews

    def dashboard_job_url job
      "#{MOUNT_JOBS}/#{job.id}" if job.respond_to? :id
    end

    def job_method_label method
      return if method.nil?
      klass = case method
      when JOB_METHOD_FILE
        "label-primary"
      when JOB_METHOD_FTP
        "label-warning"
      when JOB_METHOD_FTPS
        "label-success"
      else
        "label-default"
      end
      "<div class=\"transfer-method label #{klass}\">#{method.upcase}</div>"
    end

  end
end
