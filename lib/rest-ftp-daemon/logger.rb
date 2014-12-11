class Logger

  attr_accessor :pipe

  def info_with_id message, options = {}
    field_id = "%#{-DEFAULT_LOGS_ID_LEN.to_i}s" % options[:id].to_s
    add Logger::INFO, "#{field_id} \t#{'  '*(options[:level].to_i+1)}#{message}"
  end

end
