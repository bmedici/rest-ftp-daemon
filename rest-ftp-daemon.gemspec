# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rest-ftp-daemon/version'

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
  #spec.executables = ["rest-ftp-daemon"]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]


  spec.required_ruby_version = '>= 1.9'

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"


  # spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  # spec.files = [
  #   "Gemfile",
  #   "Gemfile.lock",
  #   "LICENSE.txt",
  #   "README.md",
  #   "Rakefile",
  #   "VERSION",
  #   "bin/rest-ftp-daemon",
  #   "lib/config.rb",
  #   "lib/config.ru",
  #   "lib/errors.rb",
  #   "lib/extend_threads.rb",
  #   "lib/rest-ftp-daemon.rb",
  #   "rest-ftp-daemon.gemspec",
  #   "test/helper.rb",
  #   "test/test_rest-ftp-daemon.rb"
  # ]
  # spec.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  # spec.rubygems_version = "2.4.1"

end

