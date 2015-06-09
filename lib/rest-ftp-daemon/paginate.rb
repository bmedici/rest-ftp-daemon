module RestFtpDaemon
  class Paginate

    def initialize data
      # Defaults
      @pages = 0
      @total = 0
      @data = []
      @only = nil
      @page = 1
      @pages = 1

      # Ensure data set is countable
      return unless data.is_a? Enumerable
      @data = data

      # Count elements
      @total = @data.count

      # Count pages
      @pages = (@total.to_f / PAGINATE_MAX).ceil
      @pages = 1 if @pages < 1
    end

    def only= raw_only
      @only = raw_only
    end

    def page= raw_page
      @page = [1, raw_page.to_i, @pages].sort[1]
    end

    def browser
      out = []
      1.upto(@pages) do |p|
        out << link(p)
      end
      out.join()
    end

    def subset
      size = PAGINATE_MAX.to_i
      offset = (@page-1) * size
      @data[offset, size]
    end

  private

    def link p
      klass = (p == @page)? ' btn-info' : ''

      "<a class='page btn btn-default%s' href='?only=%s&page=%d'>%p</a>" % [
        klass,
        @only,
        p,
        p,
      ]
    end

  end
end
