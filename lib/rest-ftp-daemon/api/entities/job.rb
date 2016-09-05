require "grape-entity"

module RestFtpDaemon
  module API
    module Entities
      class Job < Grape::Entity

        # Some formatters
        format_with(:utf8_filter) do |thing|
          thing.to_s.encode("UTF-8") if thing
        end

        # Job-execution related
        expose :id
        expose :wid, unless: lambda { |object, _options| object.wid.nil? }

        # Attributes from API
        RestFtpDaemon::Job::IMPORTED.each do |field|
          expose field
        end

        # Work-specific options
        expose :overwrite
        expose :mkdir
        expose :tempfile
        expose :video_options
        expose :video_custom

        # Status and error
        expose :status, format_with: :utf8_filter
        expose :error, format_with: :utf8_filter

        # Time stamps
        expose :queued_at
        expose :updated_at
        expose :started_at
        expose :finished_at

        # Computed fields
        expose :age           #, safe: true
        expose :exectime

        # Infos
        expose :infos, unless: :hide_infos


        # expose :slots do |station,options|
        #   station.slots.map{ |slot| SlotEntity.new(slot).serializable_hash }
        # end
      end
    end
  end
end
