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
require 'streamio-ffmpeg'
require 'active_support/core_ext/module'
require "fileutils"


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

# Jobs and locations
require_relative "rest-ftp-daemon/job"
require_relative "rest-ftp-daemon/location"


# Remotes
require_relative "rest-ftp-daemon/remote/remote"
require_relative "rest-ftp-daemon/remote/remote_file"
require_relative "rest-ftp-daemon/remote/remote_ftp"
require_relative "rest-ftp-daemon/remote/remote_sftp"
require_relative "rest-ftp-daemon/remote/remote_s3"

# Tasks
require_relative "rest-ftp-daemon/tasks/task_helpers"
require_relative "rest-ftp-daemon/tasks/task"
require_relative "rest-ftp-daemon/tasks/task_import"
require_relative "rest-ftp-daemon/tasks/task_transform"
require_relative "rest-ftp-daemon/tasks/task_transform_copy"
require_relative "rest-ftp-daemon/tasks/task_transform_ffmpeg"
require_relative "rest-ftp-daemon/tasks/task_transform_mp4split"
require_relative "rest-ftp-daemon/tasks/task_export"

# Workers
require_relative "rest-ftp-daemon/workers/worker"
require_relative "rest-ftp-daemon/workers/worker_conchita"
require_relative "rest-ftp-daemon/workers/worker_reporter"
require_relative "rest-ftp-daemon/workers/worker_job"

# API
require_relative "rest-ftp-daemon/api/api_constants"
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
