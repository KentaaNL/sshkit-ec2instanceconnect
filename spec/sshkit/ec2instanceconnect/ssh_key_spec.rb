# frozen_string_literal: true

RSpec.describe SSHKit::EC2InstanceConnect::SSHKey do
  subject(:ssh_key) { described_class.new(size: 2048) }

  describe '#private_key' do
    it 'generates a private key' do
      expect(ssh_key.private_key).not_to be_nil
      expect(ssh_key.private_key).to start_with('-----BEGIN RSA PRIVATE KEY-----')
    end
  end

  describe '#public_key' do
    it 'generates a public key in SSH format' do
      expect(ssh_key.public_key).not_to be_nil
      expect(ssh_key.public_key).to start_with('ssh-rsa')
    end
  end
end
