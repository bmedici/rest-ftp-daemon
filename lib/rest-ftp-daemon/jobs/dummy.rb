module RestFtpDaemon
  class JobDummy < JobCommon

    def initialize job_id, params = {}
      super
    end

    def process
      set_status JOB_STATUS_PREPARED
      log_info "JobDummy.process YEAH WE'RE PROCESSING, man !"
      sleep 5
      set_status JOB_STATUS_FINISHED
    end

  end
end
