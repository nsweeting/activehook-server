module ActiveHook
  module Server
    class Send
      REQUEST_HEADERS = {
        "Content-Type" => "application/json",
        "Accept"       => "application/json",
        "User-Agent"   => "ActiveHook/#{Server::VERSION}"
      }.freeze

      attr_accessor :message
      attr_reader :response_time, :status, :response

      def initialize(options = {})
        options.each { |key, value| send("#{key}=", value) }
      end

      def start
        @status = post_message
        log_status
      end

      def uri
        @uri ||= URI.parse(@message.uri)
      end

      def success?
        @status == :success
      end

      private

      def post_message
        http = Net::HTTP.new(uri.host, uri.port)
        measure_response_time do
          @response = http.post(uri.path, @message.final_payload, final_headers)
        end
        response_status(@response)
      rescue
        :error
      end

      def measure_response_time
        start = Time.now
        yield
        finish = Time.now
        @response_time = "| #{((finish - start) * 1000.0).round(3)} ms"
      end

      def response_status(response)
        case response.code.to_i
        when (200..204)
          :success
        when (400..499)
          :bad_request
        when (500..599)
          :server_problems
        end
      end

      def log_status
        msg = "POST | #{uri} | #{status.upcase} #{response_time}"
        if status == :success
          Server.log.info(msg)
        else
          Server.log.err(msg)
        end
      end

      def final_headers
        { "X-Hook-Signature" => @message.signature }.merge(REQUEST_HEADERS)
      end
    end
  end
end
