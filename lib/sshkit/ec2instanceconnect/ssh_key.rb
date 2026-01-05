# frozen_string_literal: true

require 'net/ssh'
require 'openssl'

module SSHKit
  module EC2InstanceConnect
    # Generate a private/public SSH keypair.
    class SSHKey
      def initialize(size:)
        @key = OpenSSL::PKey::RSA.generate(size)
      end

      def private_key
        @key.to_pem
      end

      def public_key
        blob = @key.public_key.to_blob
        encoded = [blob].pack('m0')

        "ssh-rsa #{encoded}"
      end
    end
  end
end
