module RestFtpDaemon::Remote
  class RemoteError                 < StandardError; end
  class RemoteConnectError          < RemoteError; end
  class RemoteUploadError             < RemoteError; end

  class RemoteBase
      include BmcDaemonLib::LoggerHelper
      include CommonHelpers

      # Class options
      attr_reader :log_prefix
      attr_accessor :job

      # Delegate set_info info to Job
      delegate :set_info, to: :job

      # Plugin detection class methods
      def self.handles
        []
      end
      def self.handles? location
        self.handles.include?(location.uri.class)
      end
      # def self.handler_for location, *params
      #   Pluginator.find(Conf.app_name, extends: %i[first_ask]).
      #     first_ask(PLUGIN_REMOTE, "handles?", location)
      # end     

      # Instantiate the right subclass
      def self.build location, *params
        plugin = Pluginator.
          find(Conf.app_name, extends: %i[first_ask]).
          first_ask(PLUGIN_REMOTE, "handles?", location)
       
        return nil if plugin.nil?
        return plugin.new(location, *params)
      end     

      def initialize target, job, config
        # Init
        @target = target
        @config = config
        @job = job

        # Logger
        log_pipe :remote
      end

      def connect
        log_debug "connect: #{@target.to_connection_string}"
      end

      def size_if_exists target
        false
      end

      def remote_try_delete target
      end

      def chdir_or_create directory, mkdir = false
      end

      def upload source, target, &callback
      end

      def close
      end

      def log_context
        @job.log_context
      end

    private

      def split_path path
        return unless path.is_a? String
        return File.dirname(path), File.basename(path)
      end

      def myname
        self.class.to_s
      end

  end
end