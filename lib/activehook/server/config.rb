module ActiveHook
  module Server
    class << self
      def configure
        reset
        yield(config)
      end

      def config
        @config ||= Config.new
      end

      def reset
        @config = nil
        @connection_pool = nil
      end
    end

    class Config
      DEFAULTS = {
        workers: 2,
        queue_threads: 2,
        retry_threads: 1,
        redis_url: ENV['REDIS_URL'],
        redis_pool: 5,
        signature_header: 'X-Webhook-Signature'
      }.freeze

      attr_accessor :workers, :queue_threads, :retry_threads,
                    :redis_url, :redis_pool, :signature_header

      def initialize
        DEFAULTS.each { |key, value| send("#{key}=", value) }
      end

      def worker_options
        {
          queue_threads: queue_threads,
          retry_threads: retry_threads
        }
      end

      def manager_options
        {
          workers: workers,
          options: worker_options
        }
      end

      def redis
        {
          size: redis_pool,
          url: redis_url
        }
      end
    end
  end
end
