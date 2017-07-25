module RestFtpDaemon
  module ViewsHelper

    def dashboard_debug
      [true, 1, "on"].include? Conf.at(:dashboard, :debug)
    end

    def dashboard_feature name, enabled, message_on = "enabled", message_off = "disabled"
      # Build classes
      class_status = enabled ? 'enabled' : 'disabled'
      classes = "btn btn-default feature-#{class_status} disabled"

      # Build title
      title_status = enabled ? message_on : message_off
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

    def job_tentatives_style count
      return  "label-outline"   if count <= 0
      return  "label-info"      if count == 1
      return  "label-warning"   if count == 2
      return  "label-danger"    if count > 2
    end

    def location_style uri
      case uri
      when URI::FILE
        "info"
      when URI::FTP
        "warning"
      when URI::FTPES, URI::FTPS, URI::SFTP
        "success"
      when URI::S3
        "primary"
      when URI::Generic
        "info"
      else
        "default"
      end
    end

    def dashboard_job_class job
      pick_class_from job.status, {
        Job::STATUS_READY     => "simple",
        Job::STATUS_RUNNING   => "info",
        Job::STATUS_FINISHED  => "success",
        Job::STATUS_FAILED    => "danger",
      }
    end
    def dashboard_job_icon job
      pick_class_from job.status, {
        Job::STATUS_READY     => "time",
        Job::STATUS_RUNNING   => "cog",
        Job::STATUS_FINISHED  => "ok",
        Job::STATUS_FAILED    => "remove",
      }
    end

    def dashboard_task_class task
      pick_class_from task.status, {
        Task::STATUS_READY    => "simple",
        Task::STATUS_FINISHED => "success",
        Task::STATUS_FAILED   => "danger",
      }
    end

    def dashboard_worker_class status
      pick_class_from status, {
        Worker::STATUS_READY    => nil,
        Worker::STATUS_SLEEPING => nil,
        Worker::STATUS_WORKING  => :info,
        Worker::STATUS_FINISHED => :success,
        Worker::STATUS_CRASHED  => :warning,
        Worker::STATUS_TIMEOUT  => :warning,
        Worker::STATUS_DOWN     => :danger,
      }
    end

    def pick_class_from key, classes
      return classes[key]
    end

    def job_status job
      # Init
      out = []

      # Job status icon
      out << job_status_icon(job)

      # Return all that stuff
      return out.join()
    end

    def tasks_status job
      # Init
      out = []

      # For each task
      out << '<span class="label-group">'
      job_status_tasks job, out
      out << '</span>'

      # Return all that stuff
      return out.join()
    end

    def job_status_icon job
      # Choose icon and class
      icon = dashboard_job_icon(job)
      klass = dashboard_job_class(job)
      return sprintf(
          '<span class="task-status label label-xs label-%s" title="%s"><i class="glyphicon glyphicon-%s"></i> %s</span>',
          klass,
          job.status,
          icon,
          job.status
          )
    end

    # def job_status_flags job, out
    #   %w(queued ready running finished failed).each do |flag|
    #     out << job_status_flag(job, flag)
    #   end
    # end

    # def job_status_flag job, flag
    #   response = job.send("#{flag}?")
    #   label_style = response ? "success" : "simple"
    #   return sprintf(
    #     '<span class="label label-xs label-%s">%s</span>',
    #     label_style,
    #     flag
    #     )
    # end

    def job_status_tasks job, out
      # For each task
      out << '<span class="label-group">'
      job.tasks.each do |task|
        task_style = dashboard_task_class(task)
        task_style ||= "info"

        # Build icon title
        title = []
        title << task.name
        title << task.error.to_s if task.error

        # '<span class="transfer-type label label-xs label-%s" title="%s">', 
        out << sprintf(
          '<span class="task-status label label-xs label-%s" title="%s">',
          task_style,
          CGI.escapeHTML(title.join("\n"))
          )
        out << sprintf(
          '<i class="glyphicon glyphicon-%s"></i> %s',
          task.task_icon,
          task.complete_status_if_working
          )
        out << '</span>'
      end
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

    def location_label loc
      # Open label-group 
      out = []
      out << '<span class="label-group">'

      # Add location style
      out << sprintf(
        '<span class="transfer-type label label-xs label-%s" title="%s">', 
        location_style(loc.uri),
        loc.uri
        )
      out << loc.uri.class.name.split('::').last
      out << '</span>'

      # Try to match a prefix token
      matches = /^\[([^\[]+)\](.*)/.match(loc.original)

      # Add a prefix label, if matched
      if matches
        out << '<span class="transfer-prefix label label-xs label-simple">'
        out << matches[1]
        out << '</span>'
        text = matches[2]
      else
        text = loc.path_abs
      end

      # Add remaining stuff
      out << '</span>'
      out << ' '
      out << text

      # Output all that stuff
      return out.join()
    end

    def text_or_empty text
      return "-" if text.nil? || text.to_s.empty?
      text
    end


  end
end