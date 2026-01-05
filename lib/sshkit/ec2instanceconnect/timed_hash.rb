# frozen_string_literal: true

require 'concurrent/map'

module SSHKit
  module EC2InstanceConnect
    # A thread-safe Hash that expires keys after a given time.
    class TimedHash
      def initialize(expires_in:)
        @expires_in = expires_in
        @store = Concurrent::Map.new
      end

      def []=(key, value)
        @store[key] = { value: value, expires_at: Time.now + @expires_in }
      end

      def [](key)
        now = Time.now

        data = @store.compute_if_present(key) do |value|
          # Expired → delete by returning nil.
          if now > value[:expires_at]
            nil
          else
            value # keep
          end
        end

        data&.fetch(:value)
      end

      def size
        @store.values.count { |value| Time.now <= value[:expires_at] }
      end

      def clear
        @store.clear
      end
    end
  end
end
