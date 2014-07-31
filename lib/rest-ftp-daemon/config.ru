# Main libs
require 'sinatra'
require 'sinatra/base'
require "sinatra/json"
require "sinatra/config_file"
require 'net/ftp'
require 'json'

# My local libs
Dir[APP_ROOT+"/lib/*.rb"].each {|file| require File.expand_path file }

# Start application
run RestFtpDaemon
