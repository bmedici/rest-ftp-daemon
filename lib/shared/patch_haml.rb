module Haml
  class Buffer

    # Class options
    alias_method :haml_push_text, :push_text

    def push_text text, tab_change, dont_tab_up
      haml_push_text text.force_encoding("utf-8"), tab_change, dont_tab_up
    end

  end
end
