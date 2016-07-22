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

    def datetime_short datetime
      # return param.class
      return "-" if datetime.nil?
      return "?" unless datetime.respond_to? :to_date
      return datetime.to_datetime.strftime("%H:%M:%S") if datetime.to_date == Time.now.to_date
      datetime.to_datetime.strftime("%d/%m %H:%M:%S")
    end

  end
end
