require "grape-entity"

module RestFtpDaemon
  module Entities
    class Location < Grape::Entity

      expose :url
      #, as: 'raw'
      # expose :uri
      expose :scheme

      expose :host, unless: Proc.new {|obj| obj.host.nil?}
      expose :user, unless: Proc.new {|obj| obj.user.nil?}
      expose :port, if: Proc.new {|obj| !obj.port.nil?}

      expose :dir
      expose :name
      expose :path
      expose :filepath

      expose :aws_region ,unless: Proc.new {|obj| obj.aws_region.nil?}
      expose :aws_bucket, unless: Proc.new {|obj| obj.aws_bucket.nil?}
      expose :aws_id,     unless: Proc.new {|obj| obj.aws_id.nil?}

    end
  end
end