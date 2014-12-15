module RestFtpDaemon
  module API
    module Entities

      class JobPresenter < Grape::Entity
        # Job ID
        expose :id

        # Job specific attributes
        Job::FIELDS.each do |field|
          expose field
          #expose field, unless: lambda { |object, options| object.instance_variable_get("@#{field}").nil? }
        end

        # Technical fields
        expose :wid, unless: lambda { |object, options| object.wid.nil? }

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
