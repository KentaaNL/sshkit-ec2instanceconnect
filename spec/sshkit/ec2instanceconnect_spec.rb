# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SSHKit::EC2InstanceConnect do
  describe '.config' do
    it 'has as default logger' do
      expect(described_class.config.logger).not_to be_nil
    end

    describe '#random_tunnel_port' do
      context 'when value is an Array' do
        before { allow(described_class.config).to receive(:tunnel_ports).and_return([8000, 8001, 8002]) }

        it 'returns a secure random tunnel port' do
          expect(described_class.config.random_tunnel_port).to be_between(8000, 8002)
        end
      end

      context 'when value is a Range' do
        before { allow(described_class.config).to receive(:tunnel_ports).and_return(8000...9000) }

        it 'returns a secure random tunnel port' do
          expect(described_class.config.random_tunnel_port).to be_between(8000, 8999)
        end
      end

      context 'when value is a String' do
        before { allow(described_class.config).to receive(:tunnel_ports).and_return('8000') }

        it 'raises an ArgumentError' do
          expect { described_class.config.random_tunnel_port }.to raise_error(ArgumentError, 'tunnel_ports must be an Array or Range')
        end
      end
    end
  end

  describe '.configure' do
    it 'yields the config object' do
      yielded = nil
      described_class.configure do |c|
        yielded = c
      end
      expect(yielded).to eq(described_class.config)
    end

    it 'allows changing configuration values' do
      logger = Logger.new($stdout)

      described_class.configure do |c|
        c.logger = logger
        c.ssh_key_refresh_enabled = false
        c.tunnel_enabled = true
      end

      expect(described_class.config.logger).to eq(logger)
      expect(described_class.config.ssh_key_refresh_enabled).to be false
      expect(described_class.config.tunnel_enabled).to be true
    end

    it 'does not allow replacing the config object' do
      expect { described_class.config = SSHKit::EC2InstanceConnect::Configuration.new }.to raise_error(NoMethodError)
    end
  end
end
