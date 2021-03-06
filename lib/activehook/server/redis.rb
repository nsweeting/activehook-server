module ActiveHook
  module Server
    class << self
      attr_reader :connection_pool

      def redis
        @connection_pool ||= ConnectionPool.create
      end
    end

    class ConnectionPool
      def self.create
        ::ConnectionPool.new(size: Server.config.redis_pool) do
          Redis.new(url: Server.config.redis_url)
        end
      end
    end
  end
end
