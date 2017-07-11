require "grape-entity"

module RestFtpDaemon
  module Entities
    class Options < Grape::Entity

      # expose :opt1, documentation: { type: 'Boolean', desc: 'opt UN', required: false }
      expose :opt2
      # expose :opt6

    end
  end
end