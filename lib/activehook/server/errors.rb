module ActiveHook
  module Server
    module Errors
      class Base < StandardError
        def initialize(msg = nil)
          @message = msg
          log_error
        end

        def message
          "The following error occured: #{@message}"
        end

        private

        def log_error
          ActiveHook::Server.log.err(@message)
        end
      end

      class Config < Base; end
      class Message < Base; end
      class HTTP < Base; end
      class Send < Base; end
      class Manager < Base; end
      class Worker < Base; end
    end
  end
end
