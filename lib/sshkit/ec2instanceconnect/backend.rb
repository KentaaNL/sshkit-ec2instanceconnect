# frozen_string_literal: true

require 'aws-sdk-ec2instanceconnect'
require 'concurrent/hash'
require 'forwardable'
require 'sshkit'

module SSHKit
  module EC2InstanceConnect
    # SSHKit backend that integrates with EC2 Instance Connect.
    #
    # It ensures that SSH keys are automatically created and send to
    # the server before executing any command.  It also ensures
    # a timely refresh of the SSH key before it expires.
    class Backend < SSHKit::Backend::Abstract
      # SSH keys using EC2 Instance Connect are valid for 60 seconds,
      # so refresh them a bit earlier.
      EXPIRES_IN = 50

      # Store SSH keys per instance with expiration.
      @ssh_keys = SSHKit::EC2InstanceConnect::TimedHash.new(expires_in: EXPIRES_IN)

      @tunnels = Concurrent::Hash.new

      # Make sure to stop any tunnels before the Ruby process exits.
      at_exit { @tunnels.each_value(&:stop) }

      class << self
        attr_accessor :ssh_keys, :tunnels
      end

      extend Forwardable

      # Define delegators to the config object.
      def_delegators :config, :ssh_key_size, :random_tunnel_port, :logger
      private :ssh_key_size, :random_tunnel_port, :logger

      def initialize(host, &)
        super
        @backend = SSHKit::Backend::Netssh.new(host)
      end

      def self.configure(&)
        SSHKit::Backend::Netssh.configure(&)
      end

      def upload!(local, remote, options = {})
        ensure_connection
        @backend.send(:upload!, local, remote, options)
      end

      def download!(remote, local = nil, options = {})
        ensure_connection
        @backend.send(:download!, remote, local, options)
      end

      def execute_command(cmd)
        ensure_connection
        @backend.send(:execute_command, cmd)
      end

      private

      def ensure_connection
        if SSHKit::EC2InstanceConnect.config.tunnel_enabled
          tunnel = self.class.tunnels[instance_id] ||= setup_tunnel
          update_host_and_port(tunnel: tunnel)
        end

        if SSHKit::EC2InstanceConnect.config.ssh_key_refresh_enabled
          ssh_key = self.class.ssh_keys[instance_id] ||= refresh_ssh_key
          update_host_ssh_options(private_key: ssh_key.private_key)
        end
      end

      def setup_tunnel
        logger.debug { "Setting up tunnel for instance #{instance_id}" }

        Tunnel.new(instance_id: instance_id, port: random_tunnel_port).tap do |tunnel|
          tunnel.start

          logger.debug { "Tunnel (#{tunnel}) started for instance #{instance_id}" }
        end
      end

      def update_host_and_port(tunnel:)
        host.properties[:original_hostname] ||= host.hostname
        host.properties[:original_port] ||= host.port

        host.hostname = tunnel.host
        host.port = tunnel.port
      end

      def refresh_ssh_key
        logger.debug { "Refreshing SSH key for instance #{instance_id}" }

        SSHKey.new(size: ssh_key_size).tap do |ssh_key|
          logger.debug { "SSH key generated, sending to instance #{instance_id}" }

          send_ssh_public_key(public_key: ssh_key.public_key)
        end
      end

      def send_ssh_public_key(public_key:)
        client = Aws::EC2InstanceConnect::Client.new
        client.send_ssh_public_key(
          instance_id: instance_id,
          instance_os_user: instance_user,
          ssh_public_key: public_key
        )
      end

      def update_host_ssh_options(private_key:)
        host.ssh_options ||= {}
        host.ssh_options.merge!(
          keys: [],
          key_data: [private_key],
          keys_only: true
        )
      end

      def instance_user
        host.user
      end

      def instance_id
        host.properties.fetch(:instance_id)
      end

      def config
        SSHKit::EC2InstanceConnect.config
      end
    end
  end
end
