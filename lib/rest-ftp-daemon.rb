# Global libs
require "rubygems"
require 'bmc-daemon-lib'
require "json"
require "haml"
require "uri"
require "timeout"
require "syslog"
require "thread"
require "newrelic_rpm"
require "rollbar"

# Shared libs / monkey-patching
require_relative "shared/patch_array"
require_relative "shared/patch_haml"
require_relative "shared/patch_file"

# Helpers
require_relative "rest-ftp-daemon/helpers/common"
require_relative "rest-ftp-daemon/helpers/views"
require_relative "rest-ftp-daemon/helpers/api"
require_relative "rest-ftp-daemon/helpers/transfer"

# Project's libs
require_relative "rest-ftp-daemon/constants"
require_relative "rest-ftp-daemon/exceptions"
require_relative "rest-ftp-daemon/metrics"
require_relative "rest-ftp-daemon/paginate"
require_relative "rest-ftp-daemon/uri"
require_relative "rest-ftp-daemon/job_queue"
require_relative "rest-ftp-daemon/counters"
require_relative "rest-ftp-daemon/notification"
require_relative "rest-ftp-daemon/location"

# Remotes
require_relative "rest-ftp-daemon/remote/base"
require_relative "rest-ftp-daemon/remote/ftp"
require_relative "rest-ftp-daemon/remote/sftp"
require_relative "rest-ftp-daemon/remote/s3"

# Jobs
require_relative "rest-ftp-daemon/job"
require_relative "rest-ftp-daemon/jobs/errors"
require_relative "rest-ftp-daemon/jobs/dummy"
require_relative "rest-ftp-daemon/jobs/transfer"
require_relative "rest-ftp-daemon/jobs/workflow"
require_relative "rest-ftp-daemon/jobs/video"

# Workers
# require_from :workers
require_relative "rest-ftp-daemon/worker_pool"
require_relative "rest-ftp-daemon/workers/worker"
require_relative "rest-ftp-daemon/workers/conchita"
require_relative "rest-ftp-daemon/workers/reporter"
require_relative "rest-ftp-daemon/workers/transfer"

# Entities and API
require_relative "rest-ftp-daemon/entities/location"
require_relative "rest-ftp-daemon/entities/options"
require_relative "rest-ftp-daemon/entities/job"
require_relative "rest-ftp-daemon/api/jobs"
require_relative "rest-ftp-daemon/api/dashboard"
require_relative "rest-ftp-daemon/api/status"
require_relative "rest-ftp-daemon/api/config"
require_relative "rest-ftp-daemon/api/debug"
require_relative "rest-ftp-daemon/api/root"

# Init
require_relative "rest-ftp-daemon/initialize"


# def require_from subdir
#   path = sprintf(
#     '%s/rest-ftp-daemon/%s/*.rb',
#     File.dirname(__FILE__),
#     subdir.to_s
#     )
#   Dir.glob(path).each do |file|
#     puts "loading: #{file}"
#     require_relative file
#   end
# end
