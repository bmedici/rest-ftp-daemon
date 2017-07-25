# Global libs
require "rubygems"
require "json"
require "haml"
require "uri"
require "timeout"
require "syslog"
require "thread"
require "newrelic_rpm"
require "rollbar"
# require "securerandom"
require "double_bag_ftps"
require "net/sftp"
require "net/ftp"
require 'aws-sdk-resources'
require 'active_support/core_ext/module'
require "fileutils"
require 'pluginator'
require 'cgi'

# Constants and base exceptions
require_relative "rest-ftp-daemon/constants"

# Shared libs / monkey-patching
require 'bmc-daemon-lib'
require_relative "shared/patch_array"
require_relative "shared/patch_haml"
require_relative "shared/patch_file"

# Helpers
require_relative "rest-ftp-daemon/common_helpers"
require_relative "rest-ftp-daemon/views/views_helpers"

# Job, location, and remote
require_relative "rest-ftp-daemon/job"
require_relative "rest-ftp-daemon/location"
require_relative "rest-ftp-daemon/remote"

# Tasks
require_relative "rest-ftp-daemon/tasks/task_helpers"
require_relative "rest-ftp-daemon/tasks/task"
require_relative "rest-ftp-daemon/tasks/task_import"
require_relative "rest-ftp-daemon/tasks/task_export"
require_relative "rest-ftp-daemon/tasks/task_transform"

# Remotes
require_relative "rest-ftp-daemon/remotes/remote_file"
require_relative "rest-ftp-daemon/remotes/remote_ftp"
require_relative "rest-ftp-daemon/remotes/remote_sftp"
require_relative "rest-ftp-daemon/remotes/remote_s3"

# Workers
require_relative "rest-ftp-daemon/workers/worker"
require_relative "rest-ftp-daemon/workers/worker_conchita"
require_relative "rest-ftp-daemon/workers/worker_reporter"
require_relative "rest-ftp-daemon/workers/worker_job"

# API
require_relative "rest-ftp-daemon/api/api_helpers"
require_relative "rest-ftp-daemon/api/entities/location"
require_relative "rest-ftp-daemon/api/entities/options"
require_relative "rest-ftp-daemon/api/entities/transform"
require_relative "rest-ftp-daemon/api/entities/job"
require_relative "rest-ftp-daemon/api/endpoints/jobs"
require_relative "rest-ftp-daemon/api/endpoints/dashboard"
require_relative "rest-ftp-daemon/api/endpoints/status"
require_relative "rest-ftp-daemon/api/endpoints/config"
require_relative "rest-ftp-daemon/api/endpoints/debug"
require_relative "rest-ftp-daemon/api/root"

# Project's libs
require_relative "rest-ftp-daemon/worker_pool"
require_relative "rest-ftp-daemon/metrics"
require_relative "rest-ftp-daemon/paginate"
require_relative "rest-ftp-daemon/job_queue"
require_relative "rest-ftp-daemon/counters"
require_relative "rest-ftp-daemon/notification"
require_relative "rest-ftp-daemon/uri"
require_relative "rest-ftp-daemon/errors"


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
