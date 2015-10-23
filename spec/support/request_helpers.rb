# encoding: utf-8

require "uri"

module RequestHelpers
  PORT = 5678

  def get path, options = {}
    accept = options.delete(:accept) { :json }
    url = URI("http://localhost:#{PORT}").merge(path)
    HTTP.accept(accept).basic_auth(user: "admin", pass: "admin")
      .get(url, options)
  end

  def post path, options = {}
    accept = options.delete(:accept) { :json }
    url = URI("http://localhost:#{PORT}").merge(path)
    HTTP.accept(accept).basic_auth(user: "admin", pass: "admin")
      .post(url, options)
  end

end
