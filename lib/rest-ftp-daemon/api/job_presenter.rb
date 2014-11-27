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

        expose :started_at
        expose :updated_at
        expose :age

        # Params
        # expose :wid, unless: lambda { |object, options| object.wid.nil? }
        expose :params

      end

    end
  end
end
