module URI
  class FTPS < Generic
    DEFAULT_PORT = 990
  end
  @@schemes['FTPS'] = FTPS
end
