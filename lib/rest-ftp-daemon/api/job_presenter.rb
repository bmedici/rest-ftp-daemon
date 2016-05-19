module RestFtpDaemon
  module API
    module Entities

      class JobPresenter < Grape::Entity
        # Job ID
        expose :id

        # Job specific attributes and flags
        Job::FIELDS.each { |name| expose name }

        # Technical fields
        expose :wid, unless: lambda { |object, _options| object.wid.nil? }

        # expose :error
        expose :json_error, as: :error
        expose :json_status, as: :status
        expose :json_target, as: :target_method

        expose :queued_at
        expose :updated_at
        expose :started_at
        expose :finished_at

        # Computed fields
        expose :age
        expose :exectime

        # Params
        expose :infos, unless: :hide_infos

      end

    end
  end
end
