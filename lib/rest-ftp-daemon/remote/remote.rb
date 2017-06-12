# Handles transfers for Job class
module RestFtpDaemon
  module Remote
    class Remote
      include BmcDaemonLib::LoggerHelper
      include CommonHelpers

      # Class options
      attr_reader :log_prefix
      attr_accessor :job

      # Delegate set_info info to Job
      delegate :set_info,
        to: :job

      def initialize target, job, config, ftpes = false
        # Init
        @target = target
        @ftpes = ftpes

        # Build and empty job to protect set_info delegation
        @job = Job.new(nil, {})
        @config = config

        # Logger
        @context = context || {}

        log_pipe :remote

        # Prepare real object
        prepare
      end

      def size_if_exists target
        false
      end

      def prepare
      end

      def connect
      end

      def chdir_or_create directory, mkdir = false
      end

      def remove! target
      end

      def close
        log_debug "close"

      end

    protected

      def log_context
        @context
      end

    private

      def split_path path
        return unless path.is_a? String
        return File.dirname(path), File.basename(path)
      end

      # def extract_parent path
      #   return unless path.is_a? String
      #   m = path.match(/^(.*)\/([^\/]+)\/?$/)
      #   return m[1], m[2] unless m.nil?
      # end

      def myname
        self.class.to_s
      end

    end
  end
end