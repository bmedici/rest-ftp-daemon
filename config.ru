# Main libs
require 'sinatra/base'
require 'net/ftp'
require 'json'

# Set LOAD_PATH
# Dir[APP_ROOT+"/lib/*.rb"].each {|file| require File.expand_path file }
$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), 'lib'))

# Require REST FTP Daemon and start it
require 'rest-ftp-daemon'
run RestFtpDaemonServer
#run RfdServer
