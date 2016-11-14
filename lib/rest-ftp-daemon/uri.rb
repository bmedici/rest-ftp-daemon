module URI

  class FILE < Generic
  end

  class S3 < Generic
  end

  class FTPS < Generic
    DEFAULT_PORT = 21
  end

  class FTPES < Generic
    DEFAULT_PORT = 21
  end

  class SFTP < Generic
    DEFAULT_PORT = 22
  end

  @@schemes["FTPS"]   = FTPS
  @@schemes["FTPES"]  = FTPES
  @@schemes["SFTP"]   = SFTP
  @@schemes["S3"]     = S3
  @@schemes["FILE"]   = FILE
end