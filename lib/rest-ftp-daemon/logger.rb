class Logger

  def info_with_id message, context = {}
    # Ensure context is a hash of options
    context = {} unless context.is_a? Hash

    # Default context
    #add Logger::DEBUG,  "info_with_id/context: #{context.inspect} | #{message}"
    context[:level] ||= 0

    # Common message header
    field_wid = "%#{-DEFAULT_LOGS_COL_WID.to_i}s" % context[:wid].to_s
    field_jid = "%#{-DEFAULT_LOGS_COL_JID.to_i}s" % context[:jid].to_s
    field_id = "%#{-DEFAULT_LOGS_COL_ID.to_i}s" % context[:id].to_s
    prefix = "#{field_wid} \t#{field_jid} \t#{field_id}\t#{'  '*(context[:level].to_i+1)}"

    # Send main message
    add Logger::INFO, prefix + message.to_s

    # Dump context lines if provided
    context[:lines].each do |line|
      line.strip!
      next if line.empty?
      add Logger::INFO, prefix + '   | ' + line[0..DEFAULT_LOGS_TRIM_LINE]
    end if context[:lines].is_a? Enumerable

  end

end
