# coding: utf-8
Gem::Specification.new do |spec|

  # Project version
  spec.version                    = "2.0.0-5"

  # Project description
  spec.name                       = "rest-ftp-daemon"
  spec.authors                    = ["Bruno MEDICI"]
  spec.email                      = "rftpd-project@bmconseil.com"
  spec.description                = "A pretty simple transfer daemon, controlled with a RESTful API"
  spec.summary                    = "RESTful transfer jobs daemon"
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
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "http"
  spec.add_development_dependency "ruby-prof"

  # Runtime dependencies
  spec.add_runtime_dependency     "bmc-daemon-lib", "~> 0.10.3"
  spec.add_runtime_dependency     "json", "~> 1.8"
  spec.add_runtime_dependency     "thin", "~> 1.7"
  spec.add_runtime_dependency     "activesupport", "4.2.7.1"

  spec.add_runtime_dependency     "grape", "0.19.1"
  spec.add_runtime_dependency     "grape-entity", "0.6.0"
  spec.add_runtime_dependency     "grape-swagger", "0.26.0"
  spec.add_runtime_dependency     "grape-swagger-entity", "0.1.5"
  spec.add_runtime_dependency     "grape-swagger-representable"

  spec.add_runtime_dependency     "rest-client", "~> 1.8"
  spec.add_runtime_dependency     "api-auth"
  spec.add_runtime_dependency     "haml"
  spec.add_runtime_dependency     "facter"
  spec.add_runtime_dependency     "sys-cpu"
  spec.add_runtime_dependency     "get_process_mem"

  spec.add_runtime_dependency     "newrelic_rpm", '~> 4'
  spec.add_runtime_dependency     "rollbar"

  spec.add_runtime_dependency     "net-sftp"
  spec.add_runtime_dependency     "double-bag-ftps"
  spec.add_runtime_dependency     "aws-sdk-resources", '~> 2.6'
  spec.add_runtime_dependency     "streamio-ffmpeg"

end
