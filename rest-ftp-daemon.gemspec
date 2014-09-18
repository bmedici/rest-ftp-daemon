# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rest-ftp-daemon/config'

Gem::Specification.new do |spec|
  #spec.name = RestFtpDaemon::NAME
  spec.name = Settings[:name]
  spec.date = Time.now.strftime("%Y-%m-%d")
  spec.authors = ["Bruno MEDICI"]
  spec.email = "rest-ftp-daemon@bmconseil.com"
  spec.description = "This is a pretty simple FTP client daemon, controlled through a RESTfull API"
  spec.summary = "RESTful FTP client daemon"
  spec.homepage = "http://github.com/bmedici/rest-ftp-daemon"
  spec.licenses = ["MIT"]

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.version       = Settings[:version]

  spec.required_ruby_version = '>= 1.9.3'

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"

  spec.add_runtime_dependency "thin", "~> 1.6"
  spec.add_runtime_dependency "grape"
  spec.add_runtime_dependency "facter"
  spec.add_runtime_dependency "settingslogic"
  spec.add_runtime_dependency "json"

end
