# coding: utf-8
Gem::Specification.new do |spec|

  # Project version
  spec.version                    = "0.430.1"

  # Project description
  spec.name                       = "rest-ftp-daemon"
  spec.authors                    = ["Bruno MEDICI"]
  spec.email                      = "rest-ftp-daemon@bmconseil.com"
  spec.description                = "This is a pretty simple FTP client daemon, controlled through a RESTful API"
  spec.summary                    = "RESTful FTP client daemon"
  spec.homepage                   = "http://github.com/bmedici/rest-ftp-daemon"
  spec.licenses                   = ["MIT"]
  spec.date                       = Time.now.strftime("%Y-%m-%d")

  # List files and executables
  spec.files                      = `git ls-files -z`.
                                      split("\x0").
                                      reject{ |f| f =~ /^dashboard.+\.png/ }
  spec.executables                = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths              = ["lib"]
  spec.required_ruby_version      = ">= 2.3"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop", "~> 0.32.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "http"

  # Runtime dependencies
  spec.add_runtime_dependency     "bmc-daemon-lib", "~> 0.3.12"
  spec.add_runtime_dependency     "json", "~> 1.8"
  spec.add_runtime_dependency     "thin", "~> 1.7"
  spec.add_runtime_dependency     "activesupport", "~> 4.2"

  spec.add_runtime_dependency     "grape"
  spec.add_runtime_dependency     "grape-entity"
  spec.add_runtime_dependency     "grape-swagger"
  spec.add_runtime_dependency     "grape-swagger-entity"
  spec.add_runtime_dependency     "grape-swagger-representable"

  spec.add_runtime_dependency     "rest-client", "~> 1.8"
  spec.add_runtime_dependency     "api-auth"
  spec.add_runtime_dependency     "haml"
  spec.add_runtime_dependency     "facter"
  spec.add_runtime_dependency     "sys-cpu"
  spec.add_runtime_dependency     "get_process_mem"

  spec.add_runtime_dependency     "newrelic_rpm"
  spec.add_runtime_dependency     "rollbar"

  spec.add_runtime_dependency     "net-sftp"
  spec.add_runtime_dependency     "double-bag-ftps"
  spec.add_runtime_dependency     "aws-sdk-resources", '~> 2'
  spec.add_runtime_dependency     "streamio-ffmpeg"

end
