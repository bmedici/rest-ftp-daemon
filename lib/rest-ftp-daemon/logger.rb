class Logger
  def format_message(severity, timestamp, progname, msg)
    stamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
    progname = "%-#{Settings[:app_trim_progname]}s" % progname
    "#{stamp}  #{severity}  #{progname}  #{msg}\n"
  end
end
