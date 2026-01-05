# frozen_string_literal: true

RSpec.describe SSHKit::EC2InstanceConnect::Tunnel do
  subject(:tunnel) { described_class.new(instance_id: instance_id, host: host, port: port) }

  let(:instance_id) { 'rspec-1234567890' }
  let(:host) { 'localhost' }
  let(:port) { '2222' }

  describe 'process lifecycle' do
    let(:fake_pid) { 1234 }

    before do
      allow(PTY).to receive(:spawn) do |_cmd, &block|
        stdout = instance_double(IO)
        allow(stdout).to receive(:each_line).and_yield("Listening for connections on #{host}:#{port}\n")
        block.call(stdout, nil, fake_pid)
      end

      allow(Process).to receive(:kill)
    end

    describe '#start' do
      it 'starts and sets pid' do
        tunnel.start

        expect(tunnel.instance_variable_get(:@pid)).to eq(fake_pid)
      end
    end

    describe '#stop' do
      it 'stops and clears pid' do
        tunnel.start

        tunnel.stop

        expect(Process).to have_received(:kill).with('TERM', fake_pid)
        expect(tunnel.instance_variable_get(:@pid)).to be_nil
      end

      context 'when pid is nil' do
        it 'stop is safe when pid is nil' do
          # no start called
          expect { tunnel.stop }.not_to raise_error
        end
      end
    end
  end

  describe '#to_s' do
    it 'returns host:port' do
      expect(tunnel.to_s).to eq('localhost:2222')
    end
  end
end
