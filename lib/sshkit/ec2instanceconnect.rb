# frozen_string_literal: true

require 'logger'
require 'securerandom'

require_relative 'ec2instanceconnect/timed_hash'
require_relative 'ec2instanceconnect/ssh_key'
require_relative 'ec2instanceconnect/tunnel'
require_relative 'ec2instanceconnect/backend'
require_relative 'ec2instanceconnect/version'

module SSHKit
  # SSHKit backend that integrates with EC2 Instance Connect.
  module EC2InstanceConnect
    # :nodoc:
    class Configuration
      attr_accessor :logger, :ssh_key_refresh_enabled, :ssh_key_size, :tunnel_enabled, :tunnel_ports

      def initialize
        @logger = ::Logger.new(IO::NULL)
        @ssh_key_refresh_enabled = true
        @ssh_key_size = 3072
        @tunnel_enabled = false
        @tunnel_ports = 8000...8100
      end

      # Returns a secure random tunnel port.
      def random_tunnel_port
        random_number = SecureRandom.random_number(tunnel_ports.size)

        case tunnel_ports
        when Array
          tunnel_ports[random_number]
        when Range
          tunnel_ports.begin + random_number
        else
          raise ArgumentError, 'tunnel_ports must be an Array or Range'
        end
      end
    end

    class << self
      def config
        @config ||= Configuration.new
      end

      def configure
        yield(config)
      end
    end
  end
end
