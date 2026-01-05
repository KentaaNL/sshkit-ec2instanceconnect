# frozen_string_literal: true

require_relative 'lib/sshkit/ec2instanceconnect/version'

Gem::Specification.new do |spec|
  spec.name    = 'sshkit-ec2instanceconnect'
  spec.version = SSHKit::EC2InstanceConnect::VERSION
  spec.authors = %w[Kentaa iRaiser]
  spec.email   = ['tech-arnhem@iraiser.eu']

  spec.summary  = 'SSHKit backend that integrates with EC2 Instance Connect'
  spec.homepage = 'https://github.com/KentaaNL/sshkit-ec2instanceconnect'
  spec.license  = 'MIT'

  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files         = Dir['LICENSE.txt', 'README.md', 'lib/**/*']
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.3.0'

  spec.add_dependency 'aws-sdk-ec2instanceconnect', '~> 1.63'
  spec.add_dependency 'concurrent-ruby', '~> 1.2'
  spec.add_dependency 'logger'
  spec.add_dependency 'rake', '~> 13.0'
  spec.add_dependency 'sshkit', '~> 1.24'

  spec.add_development_dependency 'rspec', '~> 3.13'
  spec.add_development_dependency 'rubocop', '~> 1.78'
  spec.add_development_dependency 'rubocop-performance', '~> 1.25'
  spec.add_development_dependency 'rubocop-rspec', '~> 3.6'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'webmock', '~> 3.26'
end
