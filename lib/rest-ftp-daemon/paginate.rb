module RestFtpDaemon
  class Paginate

    attr_writer :filter
    attr_accessor :all

    def initialize data
      # Defaults
      @pages = 0
      @total = 0
      @data = []
      @filter = ''
      @page = 1
      @pages = 1
      @all = false

      # Ensure data set is countable
      return unless data.is_a? Enumerable
      @data = data

      # Count elements
      @total = @data.count

      # Count pages
      @pages = (@total.to_f / DEFAULT_PAGE_SIZE).ceil
      @pages = 1 if @pages < 1
    end

    def page= raw_page
      @page = [1, raw_page.to_i, @pages].sort[1]
    end

    def browser
      return if @all

      out = []
      1.upto(@pages) do |p|
        out << link(p)
      end
      out.join()
    end

    def subset
      return @data if @all

      size = DEFAULT_PAGE_SIZE.to_i
      offset = (@page-1) * size
      @data[offset, size]
    end

  private

    def link p
      klass = (p == @page)? " btn-info" : ""

      url = Helpers.dashboard_filter_url(@filter)

      "<a class='paginate btn btn-default%s' href='%s?page=%d'>%p</a>" % [
        klass,
        @filter,
        p,
        p
      ]
    end

  end
end
