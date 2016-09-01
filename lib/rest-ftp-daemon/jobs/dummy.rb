module RestFtpDaemon
  class JobDummy < Job

    # def initialize job_id, params = {}
    #   super
    # end

    def before
    end

    def work
      log_info "JobDummy.work YEAH WE'RE PROCESSING, man !"
      sleep 5
    end

    def after
    end

  end
end
