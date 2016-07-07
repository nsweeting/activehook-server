module ActiveHook
  module Server
    class Retry
      def initialize
        @done = false
      end

      def start
        until @done
          Server.redis.with do |conn|
            conn.watch(Server.config.retry_namespace) do
              retries = retrieve_retries(conn)
              update_retries(conn, retries)
            end
          end
          sleep 2
        end
      end

      def shutdown
        @done = true
      end

      private

      def retrieve_retries(conn)
        conn.zrangebyscore(Server.config.retry_namespace, 0, Time.now.to_i)
      end

      def update_retries(conn, retries)
        if retries.any?
          conn.multi do |multi|
            multi.incrby("#{Server.config.retry_namespace}:total", retries.count)
            multi.zrem(Server.config.retry_namespace, retries)
            multi.lpush(Server.config.queue_namespace, retries)
          end
        else
          conn.unwatch
        end
      end
    end
  end
end
