module RestFtpDaemon
  module ViewsHelper

    def dashboard_feature name, enabled, message_on = "enabled", message_of = "disabled"
      # Build classes
      class_status = enabled ? 'enabled' : 'disabled'
      classes = "btn btn-default feature-#{class_status}"

      # Build title
      title_status = enabled ? message_on : message_of
      title = "#{name}: #{title_status}"

      return sprintf(
        '<div class="%s" title="%s"><img src="/images/feature_%s.png" height="14" alt="%s"/></div>',
        classes,
        title,
        name,
        title
        )
    end

    def dashboard_job_url job
      "#{MOUNT_JOBS}/#{job.id}" if job.respond_to? :id
    end

    def job_runs_style runs
      return  "label-outline"   if runs <= 0
      return  "label-info"      if runs == 1
      return  "label-warning"   if runs == 2
      return  "label-danger"    if runs > 2
    end

    def location_style uri
      case uri
      when URI::FILE
        "info"
      when URI::FTP
        "warning"
      when URI::FTPES, URI::FTPS, URI::SFTP
        "success"
      else
        "default"
      end
    end

    def job_style job
      case job.type
      when JOB_TYPE_TRANSFER
        icon_klass = "transfer"
      when JOB_TYPE_VIDEO
        icon_klass = "facetime-video"
      when JOB_TYPE_DUMMY
        icon_klass = "question-sign"
      else
        icon_klass = "label-default"
      end
    end

    def location_label uri
      sprintf(
        '<div class="transfer-type label label-%s">%s</div>',
        location_style(uri),
        uri.class.name.split('::').last
        )
    end

    def job_type job
      sprintf(
          '<span class="glyphicon glyphicon-%s" alt="%s"></span>&nbsp;%s',
          job_style(job),
          job.type,
          job.type
          )
    end

    def datetime_short datetime
      # return param.class
      return "-" if datetime.nil?
      return "?" unless datetime.respond_to? :to_date
      return datetime.to_datetime.strftime("%H:%M:%S") if datetime.to_date == Time.now.to_date
      datetime.to_datetime.strftime("%d/%m %H:%M:%S")
    end

    def formatted_duration duration
      out = []

      hours = duration / (60 * 60)
      minutes = (duration / 60) % 60
      seconds = duration % 60

      out << "#{hours}h" if hours > 0
      out << "#{minutes}mn" if (minutes > 0) || (hours > 0)
      out << "#{seconds}s"

      out.join(" ")
    end

    def remove_credentials path
      return unless path.is_a? String
      path.sub(/([a-z]+:\/\/[^\/]+):[^\/]+\@/, '\1@')
    end

    def token_to_label name, url = ''
      clean_url = remove_credentials url
      sprintf '<span class="token" title="%s">%s</span>', clean_url, name
    end

    def token_highlight path
      return unless path.is_a? String
      path.gsub(/\[([^\[]+)\]/, token_to_label('\1'))
    end

    def text_or_empty text
      return "-" if text.nil? || text.empty?
      text
    end


  end
end
