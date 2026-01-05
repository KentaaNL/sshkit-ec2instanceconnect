# frozen_string_literal: true

require 'pty'

module SSHKit
  module EC2InstanceConnect
    # Manages a tunnel using the EC2 Instance Connect Endpoint Service, for secure SSH access to EC2 instances.
    class Tunnel
      attr_reader :host, :port

      def initialize(instance_id:, host: 'localhost', port: '8000')
        @instance_id = instance_id
        @host = host
        @port = port
      end

      # Start the tunnel subprocess and wait until it is listening for connections.
      def start
        mutex = Mutex.new
        condition = ConditionVariable.new
        ready = false
        error = nil

        @thread = Thread.new do
          PTY.spawn(command) do |stdout, _stdin, pid|
            @pid = pid

            stdout.each_line do |line|
              next unless line.start_with?('Listening for connections')

              mutex.synchronize do
                ready = true
                condition.signal
              end
            end
          rescue Errno::EIO
            # PTY closed — safe to ignore
          end
        rescue Errno::ENOENT => e
          mutex.synchronize do
            error = e
            condition.signal
          end
        end

        mutex.synchronize { condition.wait(mutex) until ready || error }

        raise error if error
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
