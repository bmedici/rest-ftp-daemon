require "grape-entity"

module RestFtpDaemon
  module API
    module Entities
      class Job < Grape::Entity

        # Job ID
        expose :id

        # Job specific attributes and flags
        RestFtpDaemon::Job::FIELDS.each { |name| expose name }

        # Technical fields
        expose :wid, unless: lambda { |object, _options| object.wid.nil? }

        # expose :error
        expose :json_error, as: :error
        expose :json_status, as: :status
        #expose :json_target, as: :target_method

        expose :queued_at
        expose :updated_at
        expose :started_at
        expose :finished_at

        # Computed fields
        expose :age
        expose :exectime

        # Params
        expose :infos, unless: :hide_infos

        # Options
        # expose :options, using: API::Entities::Options
        # expose :video_ac
        # expose :video_custom

        # with_options(format_with: :iso_timestamp) do
        #     expose :created_at
        #     expose :updated_at
        # end

        # expose :age do
        # end

        # expose :slots do |station,options|
        #   station.slots.map{ |slot| SlotEntity.new(slot).serializable_hash }
        # end

      private

        def priv_func
        end

      end
    end
  end
end
