# frozen_string_literal: true

require 'simplecov'

SimpleCov.configure do
  skip 'vendor/'

  minimum_coverage 100
end

SimpleCov.start

ENV['AWS_ACCESS_KEY_ID'] = 'test'
ENV['AWS_SECRET_ACCESS_KEY'] = 'test'
ENV['AWS_REGION'] = 'eu-west-1'

require 'sshkit/ec2instanceconnect'
require 'webmock/rspec'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    SSHKit::EC2InstanceConnect::Backend.ssh_keys.clear
    SSHKit::EC2InstanceConnect::Backend.tunnels.clear
  end

  # Stub calls to AWS metadata API on CI.
  if ENV['CI']
    config.before do
      stub_request(:put, 'http://169.254.169.254/latest/api/token').to_return(status: 200)

      stub_request(:get, 'http://169.254.169.254/latest/meta-data/iam/security-credentials/')
        .to_return(status: 200, body: 'DummyRole')

      stub_request(:get, 'http://169.254.169.254/latest/meta-data/iam/security-credentials/DummyRole')
        .to_return(status: 200, body: {
          Code: 'Success',
          LastUpdated: Time.now.utc.iso8601,
          Type: 'AWS-HMAC',
          AccessKeyId: SecureRandom.alphanumeric(10),
          SecretAccessKey: SecureRandom.alphanumeric(20),
          Token: SecureRandom.alphanumeric(60),
          Expiration: (Time.now + 3600).utc.iso8601
        }.to_json)
    end
  end
end
