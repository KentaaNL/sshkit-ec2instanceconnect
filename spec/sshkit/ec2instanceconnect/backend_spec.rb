# frozen_string_literal: true

RSpec.describe SSHKit::EC2InstanceConnect::Backend do
  subject(:backend) { described_class.new(host) }

  let(:host) { SSHKit::Host.new(user: 'ec2-user', hostname: 'rspec-1234567890abcdef0') }
  let(:properties) { { instance_id: 'rspec-1234567890abcdef0' } }

  let(:mocked_backend) { instance_double(SSHKit::Backend::Netssh, upload!: nil, download!: nil, execute_command: 'ok') }

  before do
    allow(host).to receive(:properties).and_return(properties)
    allow(SSHKit::Backend::Netssh).to receive(:new).with(host).and_return(mocked_backend)

    stub_request(:post, 'https://ec2-instance-connect.eu-west-1.amazonaws.com/')
      .to_return(status: 200, body: { request_id: '12345',
                                      success: true }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  describe '.configure' do
    it 'calls configure on the real backend' do
      allow(SSHKit::Backend::Netssh).to receive(:configure)

      described_class.configure

      expect(SSHKit::Backend::Netssh).to have_received(:configure)
    end
  end

  describe '#upload!' do
    let(:local) { 'test.txt' }
    let(:remote) { 'ec2-user@rspec-1234567890abcdef0' }

    it 'refreshes SSH key before executing command' do
      backend.upload!(local, remote)

      expect(WebMock).to have_requested(:post, 'https://ec2-instance-connect.eu-west-1.amazonaws.com/')
    end

    it 'calls the real backend' do
      backend.upload!(local, remote)

      expect(mocked_backend).to have_received(:upload!).with(local, remote, {})
    end
  end

  describe '#download!' do
    let(:local) { 'test.txt' }
    let(:remote) { 'ec2-user@rspec-1234567890abcdef0' }

    it 'refreshes SSH key before executing command' do
      backend.download!(remote, local)

      expect(WebMock).to have_requested(:post, 'https://ec2-instance-connect.eu-west-1.amazonaws.com/')
    end

    it 'calls the real backend' do
      backend.download!(remote, local)

      expect(mocked_backend).to have_received(:download!).with(remote, local, {})
    end
  end

  describe '#execute_command' do
    let(:command) { SSHKit::Command.new('example', host: host) }

    it 'refreshes SSH key before executing command' do
      backend.execute_command(command)

      expect(WebMock).to have_requested(:post, 'https://ec2-instance-connect.eu-west-1.amazonaws.com/')
    end

    it 'calls the real backend' do
      backend.execute_command(command)

      expect(mocked_backend).to have_received(:execute_command).with(command)
    end

    it 'updates the host ssh options with the private key data' do
      expect do
        backend.execute_command(command)
      end.to change(host, :ssh_options).from(nil).to(hash_including(:key_data, :keys, :keys_only))
    end

    context 'when SSH key has been expired' do
      before do
        backend.class.instance_variable_set(:@ssh_keys, SSHKit::EC2InstanceConnect::TimedHash.new(expires_in: 0.1))
      end

      it 'refreshes SSH key before executing command' do
        backend.execute_command(command)
        sleep 0.2
        backend.execute_command(command)

        expect(WebMock).to have_requested(:post, 'https://ec2-instance-connect.eu-west-1.amazonaws.com/').twice
      end
    end

    context 'with tunnel enabled' do
      let(:tunnel) { instance_double(SSHKit::EC2InstanceConnect::Tunnel, host: 'localhost', port: '9000', start: nil) }

      before do
        allow(SSHKit::EC2InstanceConnect.config).to receive(:tunnel_enabled).and_return(true)
        allow(SSHKit::EC2InstanceConnect::Tunnel).to receive(:new).and_return(tunnel)
      end

      it 'starts a new tunnel' do
        backend.execute_command(command)

        expect(tunnel).to have_received(:start)
      end

      it 'updates the host and port to the tunnel' do
        backend.execute_command(command)

        expect(host.hostname).to eq('localhost')
        expect(host.port).to eq('9000')
      end
    end
  end
end
