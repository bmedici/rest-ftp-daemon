require 'rubygems'
require 'sinatra/base'

class RestFtpDaemon < Sinatra::Base

  get "/" do
    "Your skinny daemon is up and running."
  end

end
