# coding: utf-8

# Libs
#require "settingslogic"
app_root = File.dirname(__FILE__)
require File.expand_path("#{app_root}/lib/rest-ftp-daemon/constants")

# Gemspec
Gem::Specification.new do |spec|
  spec.name = APP_NAME
  spec.date = Time.now.strftime("%Y-%m-%d")
  spec.authors = ["Bruno MEDICI"]
  spec.email = "rest-ftp-daemon@bmconseil.com"
  spec.description = "This is a pretty simple FTP client daemon, controlled through a RESTful API"
  spec.summary = "RESTful FTP client daemon"
  spec.homepage = "http://github.com/bmedici/rest-ftp-daemon"
  spec.licenses = ["MIT"]

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.version       = APP_VER

  #spec.required_ruby_version = '>= 1.9.3'
  spec.required_ruby_version = ">= 2.1"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.1"

  spec.add_runtime_dependency "thin", "~> 1.6"
  spec.add_runtime_dependency "grape"
  spec.add_runtime_dependency "grape-entity"
  spec.add_runtime_dependency "settingslogic"
  spec.add_runtime_dependency "haml"
  spec.add_runtime_dependency "json"
  spec.add_runtime_dependency "double-bag-ftps"
  spec.add_runtime_dependency "facter"
  spec.add_runtime_dependency "sys-cpu"
  spec.add_runtime_dependency "timeout"
  spec.add_runtime_dependency "get_process_mem"
  spec.add_runtime_dependency "newrelic_rpm"
end
