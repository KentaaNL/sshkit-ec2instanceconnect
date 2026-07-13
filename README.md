# sshkit-ec2instanceconnect

[![Gem Version](https://badge.fury.io/rb/sshkit-ec2instanceconnect.svg)](https://badge.fury.io/rb/sshkit-ec2instanceconnect)
[![Build Status](https://github.com/KentaaNL/sshkit-ec2instanceconnect/actions/workflows/test.yml/badge.svg)](https://github.com/KentaaNL/sshkit-ec2instanceconnect/actions)
[![CodeQL](https://github.com/KentaaNL/sshkit-ec2instanceconnect/actions/workflows/github-code-scanning/codeql/badge.svg)](https://github.com/KentaaNL/sshkit-ec2instanceconnect/actions/workflows/github-code-scanning/codeql)

A [SSHKit](https://github.com/capistrano/sshkit) backend that integrates with
[AWS EC2 Instance Connect](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/connect-linux-inst-eic.html) .

This backend automatically generates ephemeral SSH keys, delivers the public key to the target instance using EC2 Instance Connect, and refreshes the key before it expires. It is designed for use with [Capistrano](https://github.com/capistrano/capistrano) deployments on AWS.

Additionally, the backend can optionally connect through an [EC2 Instance Connect Endpoint](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/connect-with-ec2-instance-connect-endpoint.html) by establishing a tunnel and routing SSH traffic through it.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sshkit-ec2instanceconnect'
```

## Configuration

Global configuration can be set during application boot (e.g., in a Capistrano initializer).
Default configuration:

```ruby
SSHKit::EC2InstanceConnect.configure do |config|
  config.ssh_key_refresh_enabled = true   # Enable ephemeral SSH keys and refresh them periodically
  config.ssh_key_size = 3072              # Ephemeral SSH key size (RSA)
  config.tunnel_enabled = false           # Enable EC2 Instance Connect Endpoint tunneling
  config.tunnel_ports = 8000...8100       # Local port range used when allocating a tunnel
end
```

To use this backend with Capistrano, add to your `config/deploy.rb`:

```ruby
set :sshkit_backend, SSHKit::EC2InstanceConnect::Backend
```

Ensure your server definitions include the `instance_id` property:

```ruby
server 'ec2-hostname', user: 'ec2-user', roles: %w[app web], instance_id: 'i-0abcdef1234567890'
```

When using [capistrano-asg-rolling](https://github.com/KentaaNL/capistrano-asg-rolling), no additional configuration is needed; it automatically passes the correct `instance_id` to the backend.

## EC2 Instance Connect Endpoint (Tunneling)

This gem supports connecting to EC2 instances through an [EC2 Instance Connect Endpoint](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/connect-with-ec2-instance-connect-endpoint.html) by invoking the AWS CLI command `aws ec2-instance-connect open-tunnel`.

When tunneling is enabled:
1. A local port is selected from the configured `tunnel_ports` range.
2. A tunnel is opened to the target instance through the EC2 Instance Connect Endpoint.
3. SSHKit connects through the tunnel transparently.
4. The tunnel is automatically closed when the session ends.

This is particularly useful in VPC environments where instances do not have public IPs and can only be accessed through an EC2 Instance Connect Endpoint.

To enable tunneling, set:

```ruby
config.tunnel_enabled = true
```

**Note**: Tunneling requires the AWS CLI (`aws ec2-instance-connect`) to be installed and configured.

Since the host's `hostname`/`port` are overwritten to point at the local tunnel, the original values remain available on `host.properties[:original_hostname]` / `host.properties[:original_port]` for logging or diagnostics.

## IAM Policy

Sending ephemeral SSH keys and opening tunnels require the correct IAM permissions.
For example:

### EC2 Instance Connect

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": ["ec2-instance-connect:SendSSHPublicKey"],
            "Resource": "*"
        }
    ]
}
```

### EC2 Instance Connect Endpoint (Tunneling)

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": ["ec2-instance-connect:OpenTunnel"],
            "Resource": "*"
        }
    ]
}
```

Please refer to the AWS documentation for further details.
