class Thread

  def job
    # Basic fields
    job = self[:job]

    # Calculated fields
    job[:id] = self[:id]
    job[:runtime] = (Time.now - job[:created]).round(1)

    return job
  end

end
