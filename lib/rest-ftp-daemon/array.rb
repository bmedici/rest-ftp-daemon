class Array
  def sum
    self.inject{|sum,x| sum + x }
  end
end
