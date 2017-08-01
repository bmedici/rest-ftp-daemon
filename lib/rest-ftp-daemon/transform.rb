module RestFtpDaemon::Transform
  class TransformError            < RestFtpDaemon::Task::TaskError; end
  class TransformMissingBinary    < TransformError; end
  class TransformMissingOutput    < TransformError; end
  class TransformMissingOptions   < TransformError; end
  class TransformFileNotFound     < TransformError; end

  class TransformBase < Task::TaskTransform

    def self.for_plugin plugin
      Pluginator.
        find(Conf.app_name, extends: %i[first_class]).
        first_class(PLUGIN_TRANSFORM, plugin.join('_'))
    end     

  end
end
