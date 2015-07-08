module URI

  class FTPS < Generic
    DEFAULT_PORT = 21
  end

  class FTPES < Generic
    # DEFAULT_PORT = 990
    DEFAULT_PORT = 21
  end
  @@schemes["FTPS"] = FTPS
  @@schemes["FTPES"] = FTPES
end
