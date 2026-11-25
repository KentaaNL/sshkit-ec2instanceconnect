# frozen_string_literal: true

require 'pty'

module SSHKit
  module EC2InstanceConnect
    # Raised when the tunnel process exits or times out before listening for connections.
    class TunnelError < StandardError; end

    # Manages a tunnel using the EC2 Instance Connect Endpoint Service, for secure SSH access to EC2 instances.
    class Tunnel
      START_TIMEOUT = 30

      attr_reader :host, :port

      def initialize(instance_id:, host: 'localhost', port: '8000')
        @instance_id = instance_id
        @host = host
        @port = port
      end

      # Start the tunnel subprocess and wait until it is listening for connections.
      def start
        queue = Thread::Queue.new
        output = []
        ready = false

        @thread = Thread.new do
          PTY.spawn(command) do |stdout, _stdin, pid|
            @pid = pid

            # Keep draining stdout after startup so the PTY buffer doesn't fill up, but stop collecting output.
            stdout.each_line do |line|
              next if ready

              output << line
              ready = line.start_with?('Listening for connections')
              queue << :ready if ready
            end
          rescue Errno::EIO
            # PTY closed — safe to ignore
          end

          queue << TunnelError.new("Tunnel for instance #{@instance_id} exited before listening on #{self}: #{output.join.strip}") unless ready
        rescue SystemCallError => e
          queue << e
        end

        result = queue.pop(timeout: START_TIMEOUT)
        return if result == :ready

        stop
        raise result || TunnelError.new("Tunnel for instance #{@instance_id} did not start listening on #{self} within #{START_TIMEOUT}s")
      end

      # Stop the tunnel process.
      def stop
        return if @pid.nil?

        begin
          Process.kill('TERM', @pid)
        rescue Errno::ESRCH
          # Process already exited — safe to ignore
        end
        @pid = nil

        @thread&.join
      end

      def to_s
        "#{@host}:#{@port}"
      end

      private

      # Generate the AWS CLI command to open the tunnel.
      def command
        "aws ec2-instance-connect open-tunnel --instance-id #{@instance_id} --local-port #{@port}"
      end
    end
  end
end
