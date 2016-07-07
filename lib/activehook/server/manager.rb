module ActiveHook
  module Server
    # The Manager controls our Worker processes. We use it to instruct each
    # of them to start and shutdown.
    #
    class Manager
      attr_accessor :workers, :options
      attr_reader :forks

      def initialize(options = {})
        options.each { |key, value| send("#{key}=", value) }
        @master = Process.pid
        @forks = []
        at_exit { shutdown }
      end

      # Instantiates new Worker objects, setting them with our options. We
      # follow up by booting each of our Workers. Our Manager is then put to
      # sleep so that our Workers can do their thing.
      #
      def start
        validate!
        start_messages
        create_workers
        Process.wait
      end

      # Shutsdown our Worker processes.
      #
      def shutdown
        unless @forks.empty?
          @forks.each { |w| Process.kill('SIGTERM', w[:pid].to_i) }
        end
        Process.kill('SIGTERM', @master)
      end

      private

      # Create the specified number of workers and starts them
      #
      def create_workers
        @workers.times do |id|
          pid = fork { Worker.new(@options.merge(id: id)).start }
          @forks << { id: id, pid: pid }
        end
      end

      # Information about the start process
      #
      def start_messages
        Server.log.info("* Workers: #{@workers}")
        Server.log.info("* Threads: #{@options[:queue_threads]} queue, #{@options[:retry_threads]} retry")
      end

      # Validates our data before starting our Workers. Also instantiates our
      # connection pool by pinging Redis.
      #
      def validate!
        validate_redis
        validate_workers
        validate_options
      end

      def validate_redis
        Server.redis.with { |c| c.ping && c.quit }
      rescue
        raise Errors::Manager, 'Cound not connect to Redis.'
      end

      def validate_workers
        return if @workers.is_a?(Integer)
        raise Errors::Manager, 'Workers must be an Integer.'
      end

      def validate_options
        return if @options.is_a?(Hash)
        raise Errors::Manager, 'Options must be a Hash.'
      end
    end
  end
end
