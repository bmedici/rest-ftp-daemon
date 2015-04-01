class Logger

  def info_with_id message, context = {}
    # Ensure context is a hash of options and init
    context = {} unless context.is_a? Hash
    context[:level] ||= Logger::DEBUG

    # Build prefixes depending on this context
    prefix1 = build_prefix(context)
    prefix2 = build_prefix() + '   | '

    # Build output lines
    output = []
    output << prefix1 + message.strip

    # Add optional lines
    context[:lines].each do |line|
      line.strip!
      next if line.empty?
      output << prefix2 + line[0..LOG_TRIM_LINE]
    end if context[:lines].is_a? Enumerable

    # Send all this to logger
    add context[:level], output
  end

  def build_prefix context = {}
    LOG_FORMAT_MESSAGE % [
      context[:wid].to_s,
      context[:jid].to_s,
      context[:id].to_s,
      context[:level].to_i+1,
    ]
  end

end
