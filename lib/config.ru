# Main libs
require 'sinatra'
require 'sinatra/base'
require 'net/ftp'
require 'json'

# My local libs
#Dir[APP_ROOT+"/lib/*.rb"].each {|file| require File.expand_path file }
#Dir[APP_ROOT+"/lib/*/*.rb"].each {|file| require File.expand_path file }

require 'rest-ftp-daemon/config'
require 'rest-ftp-daemon/errors'
require 'rest-ftp-daemon/extend_threads'
require 'rest-ftp-daemon/version'
#require 'rest-ftp-daemon/config'

# Start application
run RestFtpDaemon
