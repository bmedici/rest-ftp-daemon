# Main libs
require 'sinatra'
require 'sinatra/base'
require 'net/ftp'
require 'json'
require 'syslog-logger'

# My local libs
Dir[APP_ROOT+"/lib/*.rb"].each {|file| require File.expand_path file }

# Start application
run RestFtpDaemon
