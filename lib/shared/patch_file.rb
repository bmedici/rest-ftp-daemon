class File
  def each_part(size)
    yield read(size) until eof?
  end
end