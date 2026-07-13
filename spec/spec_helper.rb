# frozen_string_literal: true

require 'simplecov'

SimpleCov.configure do
  skip 'vendor/'

  minimum_coverage 100
end

SimpleCov.start

require 'sshkit/ec2instanceconnect'
require 'webmock/rspec'

# Give the SDK a region and dummy credentials so it can sign requests without
# resolving real ones. The HTTP calls themselves are stubbed by WebMock.
Aws.config.update(
  region: 'eu-west-1',
  credentials: Aws::Credentials.new('test', 'test')
)

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
end
