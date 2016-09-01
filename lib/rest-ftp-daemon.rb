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


# Shared libs / monkey-patching
require_relative "shared/patch_array"
require_relative "shared/patch_haml"


# Project's libs
require_relative "rest-ftp-daemon/constants"
require_relative "rest-ftp-daemon/exceptions"
require_relative "rest-ftp-daemon/helpers/common"
require_relative "rest-ftp-daemon/helpers/views"
require_relative "rest-ftp-daemon/helpers/api"
require_relative "rest-ftp-daemon/metrics"
require_relative "rest-ftp-daemon/paginate"
require_relative "rest-ftp-daemon/uri"
require_relative "rest-ftp-daemon/job_queue"
require_relative "rest-ftp-daemon/counters"
require_relative "rest-ftp-daemon/notification"
require_relative "rest-ftp-daemon/location"

require_relative "rest-ftp-daemon/remote"
require_relative "rest-ftp-daemon/remote_ftp"
require_relative "rest-ftp-daemon/remote_sftp"

require_relative "rest-ftp-daemon/job"
require_relative "rest-ftp-daemon/jobs/errors"
require_relative "rest-ftp-daemon/jobs/dummy"
require_relative "rest-ftp-daemon/jobs/transfer"
require_relative "rest-ftp-daemon/jobs/video"

require_relative "rest-ftp-daemon/worker_pool"
require_relative "rest-ftp-daemon/workers/worker"
require_relative "rest-ftp-daemon/workers/conchita"
require_relative "rest-ftp-daemon/workers/reporter"
require_relative "rest-ftp-daemon/workers/transfer"

require_relative "rest-ftp-daemon/api/entities/options"
require_relative "rest-ftp-daemon/api/entities/job"

require_relative "rest-ftp-daemon/api/jobs"
require_relative "rest-ftp-daemon/api/dashboard"
require_relative "rest-ftp-daemon/api/status"
require_relative "rest-ftp-daemon/api/config"
require_relative "rest-ftp-daemon/api/debug"
require_relative "rest-ftp-daemon/api/root"

