require 'sinatra'
require 'sinatra/base'
require "sinatra/json"
require "sinatra/config_file"
require 'net/ftp'
require 'json'

class RestFtpDaemon < Sinatra::Base

  get "/" do
    "Your skinny daemon is up and running"
  end

end
