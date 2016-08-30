require "grape-entity"

module RestFtpDaemon
  module API
    module Entities
      class Options < Grape::Entity

        expose :opt1, documentation: { type: 'Boolean', desc: 'opt UN' }
        expose :opt2
        expose :opt6

      end
    end
  end
end
