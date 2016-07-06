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
          @forks.each { |w| Process.kill('SIGINT', w[:pid].to_i) }
        end
        Process.kill('SIGINT', @master)
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
        ActiveHook::Server.log.info("* Workers: #{@workers}")
        ActiveHook::Server.log.info("* Threads: #{@options[:queue_threads]} queue, #{@options[:retry_threads]} retry")
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
        ActiveHook::Server.redis.with { |c| c.ping && c.quit }
      rescue
        msg = 'Cound not connect to Redis.'
        ActiveHook::Server.log.err(msg)
        raise Errors::Manager, msg
      end

      def validate_workers
        return if @workers.is_a?(Integer)
        msg = 'Workers must be an Integer.'
        raise Errors::Manager, msg
      end

      def validate_options
        return if @options.is_a?(Hash)
        raise Errors::Manager, 'Options must be a Hash.'
      end
    end
  end
end
