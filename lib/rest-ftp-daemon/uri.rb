module URI
  class FTPS < Generic
    DEFAULT_PORT = 21
  end
  @@schemes['FTPS'] = FTPS
end
module URI
  class FTPES < Generic
    DEFAULT_PORT = 990
  end
  @@schemes['FTPES'] = FTPES
end
