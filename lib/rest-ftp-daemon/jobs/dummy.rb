module RestFtpDaemon
  class JobDummy < Job

    # def initialize job_id, params = {}
    #   super
    # end
  protected

    def do_before
    end

      log_info "JobDummy.work YEAH WE'RE PROCESSING, man !"
    def do_work
      sleep 5
    end

    def do_after
    end

  end
end
