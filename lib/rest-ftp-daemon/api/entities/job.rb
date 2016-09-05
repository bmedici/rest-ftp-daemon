require "grape-entity"

module RestFtpDaemon
  module API
    module Entities
      class Job < Grape::Entity

        # Job ID
        expose :id

        # Job specific attributes and flags
        RestFtpDaemon::Job::FIELDS.each { |name| expose name }
        # Some formatters
        format_with(:utf8_filter) do |thing|
          thing.to_s.encode("UTF-8") if thing
        end

        # Technical fields
        expose :wid, unless: lambda { |object, _options| object.wid.nil? }


        # Status and error
        expose :status, format_with: :utf8_filter
        expose :error, format_with: :utf8_filter

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
      end
    end
  end
end
