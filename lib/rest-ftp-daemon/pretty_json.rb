module PrettyJSON
  def self.call(object, env)
    JSON.pretty_generate(JSON.parse(object.to_json))
  end
end
