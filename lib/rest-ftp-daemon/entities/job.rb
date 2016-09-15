require "grape-entity"

module RestFtpDaemon
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

      # Job/Video options
      expose :video_options
      expose :video_custom

      # Status and error
      expose :status, format_with: :utf8_filter
      expose :error, format_with: :utf8_filter

      # Time stamps
      expose :updated_at
      expose :created_at
      expose :created_since       #, safe: true

      expose :started_at
      expose :started_since
      expose :finished_at

      # Computed fields


      # Infos
      expose :infos, unless: :hide_infos

      # Source and target     #, :unless => Proc.new {|g| g.source_loc.nil?}
      expose :source_loc, using: Entities::Location#, as: :source
      expose :target_loc, using: Entities::Location#, as: :target

      # expose :slots do |station,options|
      #   station.slots.map{ |slot| SlotEntity.new(slot).serializable_hash }
      # end
    end
  end
end
