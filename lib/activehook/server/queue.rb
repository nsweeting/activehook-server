module ActiveHook
  module Server
    # The Queue object processes any messages that are queued into our Redis server.
    # It will perform a 'blocking pop' on our message list until one is added.
    #
    class Queue
      def initialize
        @done = false
      end

      # Starts our queue process. This will run until instructed to stop.
      #
      def start
        until @done
          json = retrieve_message
          MessageRunner.new(json) if json
        end
      end

      # Shutsdown our queue process.
      #
      def shutdown
        @done = true
      end

      private

      # Performs a 'blocking pop' on our redis queue list.
      #
      def retrieve_message
        json = ActiveHook::Server.redis.with { |c| c.brpop('ah:queue') }
        json.last if json
      end
    end

    class MessageRunner
      def initialize(json)
        @message = Message.new(JSON.parse(json))
        @post = Send.new(message: @message)
        start
      end

      def start
        @post.start
        ActiveHook::Server.redis.with do |conn|
          @post.success? ? message_success(conn) : message_failed(conn)
        end
      end

      private

      def message_success(conn)
        conn.incr('ah:total_success')
      end

      def message_failed(conn)
        conn.incr('ah:total_failed')
        return unless @message.retry?
        conn.zadd('ah:retry', @message.retry_at, @message.to_json)
      end
    end
  end
end
