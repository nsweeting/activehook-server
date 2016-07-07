module ActiveHook
  module Server
    class Message
      attr_accessor :token, :uri, :id, :key, :retry_max, :retry_time, :created_at
      attr_reader :errors, :payload

      def initialize(options = {})
        options = defaults.merge(options)
        options.each { |key, value| send("#{key}=", value) }
        @errors = {}
      end

      def save
        return false unless valid?
        save_message ? true : false
      end

      def payload=(payload)
        if payload.is_a?(String)
          @payload = JSON.parse(payload)
        else
          @payload = payload
        end
      rescue JSON::ParserError
        @payload = nil
      end

      def retry?
        fail_at > Time.now.to_i
      end

      def retry_at
        Time.now.to_i + @retry_time.to_i
      end

      def fail_at
        @created_at.to_i + retry_max_time
      end

      def retry_max_time
        @retry_time.to_i * @retry_max.to_i
      end

      def to_json
        { id: @id,
          key: @key,
          token: @token,
          created_at: @created_at,
          retry_time: @retry_time,
          retry_max: @retry_max,
          uri: @uri,
          payload: @payload }.to_json
      end

      def final_payload
        { id: @id,
          key: @key,
          created_at: @created_at,
          payload: @payload }.to_json
      end

      def signature
        OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), @token, final_payload)
      end

      def valid?
        validate!
        @errors.empty?
      end

      private

      def save_message
        Server.redis.with do |conn|
          @id = conn.incr("#{Server.config.queue_namespace}:total")
          conn.lpush(Server.config.queue_namespace, to_json)
        end
      rescue
        @errors.merge!(message: ['encountered server issues.'])
        false
      end

      def defaults
        { key: SecureRandom.uuid,
          created_at: Time.now.to_i,
          retry_time: 3600,
          retry_max: 3 }
      end

      def validate!
        @errors.merge!(token: ['must be a string.']) unless @token.is_a?(String)
        @errors.merge!(payload: ['must be a Hash']) unless @payload.is_a?(Hash)
        @errors.merge!(uri: ['is not a valid format.']) unless @uri =~ /\A#{URI::regexp}\z/
        @errors.merge!(created_at: ['must be an Integer.']) unless @created_at.is_a?(Integer)
        @errors.merge!(retry_time: ['must be an Integer.']) unless @retry_time.is_a?(Integer)
        @errors.merge!(retry_max: ['must be an Integer.']) unless @retry_max.is_a?(Integer)
      end
    end
  end
end
