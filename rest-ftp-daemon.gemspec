# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'version.rb'

Gem::Specification.new do |spec|
  spec.name = "rest-ftp-daemon"
  spec.version = "0.20.0"
  spec.date = "2014-08-14"
  spec.authors = ["Bruno MEDICI"]
  spec.email = "rest-ftp-daemon@bmconseil.com"
  spec.description = "This is a pretty simple FTP client daemon, controlled through a RESTfull API"
  spec.summary = "RESTful FTP client daemon"
  spec.homepage = "http://github.com/bmedici/rest-ftp-daemon"
  spec.licenses = ["MIT"]
  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.required_ruby_version = '>= 1.9'

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end

