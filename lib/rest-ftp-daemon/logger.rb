require "logger"

class Logger

  def info_with_id message, context = {}
    # Ensure context is a hash of options and init
    context = {} unless context.is_a? Hash
    context[:level] ||= Logger::DEBUG

    # Build prefixes depending on this context
    prefix1 = build_prefix(context)
    prefix2 = build_prefix() + "   | "

    lines = context[:lines]

    if lines.is_a? Hash
      output = build_from_hash prefix2, lines

    elsif lines.is_a? Array
      output = build_from_array prefix2, lines

    else
      output = []

    end

    # Prepend plain message to output
    #output.unshift (prefix1 + message.strip)
    output.unshift (prefix1 + message)

    # Send all this to logger
    add context[:level], output
  end

  def build_prefix context = {}
    LOG_FORMAT_MESSAGE % [
      context[:wid].to_s,
      context[:jid].to_s,
      context[:id].to_s,
      context[:level].to_i+1
    ]
  end

  protected

    def build_from_array prefix, lines
      lines.map do |value|
        #text = value.to_s.strip[0..LOG_TRIM_LINE]
        text = value.to_s[0..LOG_TRIM_LINE]
        "#{prefix}#{text}"
      end
    end

    def build_from_hash prefix, lines
      lines.map do |name, value|
        text = value.to_s.strip[0..LOG_TRIM_LINE]
        "#{prefix}#{name}: #{text}"
      end
    end

end
