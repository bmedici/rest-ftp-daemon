require "grape-entity"

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

        expose :error
        expose :status
        expose :queued_at
        expose :updated_at
        expose :started_at
        expose :finished_at

        # Computed fields
        expose :age
        expose :exectime

        # Params
        expose :params, unless: :hide_params

      end

    end
  end
end
