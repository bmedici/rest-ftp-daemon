module RestFtpDaemon
  class JobDummy < Job

  protected

    def do_before
      log_info "JobDummy.do_before"
    end

    def do_work
      log_info "JobDummy.do_work"
      sleep 5
    end

    def do_after
      log_info "JobDummy.do_after"
    end

  end
end
