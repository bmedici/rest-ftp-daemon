# encoding: utf-8

require "uri"

module RequestHelpers
  PORT = 5678

  def get(path, options = {})
    url = URI("http://localhost:#{PORT}").merge(path)
    HTTP.accept(:json).basic_auth(user: 'admin', pass: 'admin').
      get(url, options)
  end

  def post(path, options = {})
    url = URI("http://localhost:#{PORT}").merge(path)
    HTTP.accept(:json).basic_auth(user: 'admin', pass: 'admin').
      post(url, options)
  end

end
