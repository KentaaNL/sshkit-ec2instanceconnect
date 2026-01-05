# frozen_string_literal: true

RSpec.describe SSHKit::EC2InstanceConnect::TimedHash do
  subject(:timed_hash) { described_class.new(expires_in: expires_in) }

  let(:expires_in) { 0.1 }

  describe '#[]=' do
    it 'stores a value with a key' do
      timed_hash[:foo] = 'bar'
      expect(timed_hash[:foo]).to eq('bar')
    end
  end

  describe '#[]' do
    it 'returns nil for missing key' do
      expect(timed_hash[:missing]).to be_nil
    end

    it 'returns value before expiration' do
      timed_hash[:foo] = 'bar'
      expect(timed_hash[:foo]).to eq('bar')
    end

    it 'returns nil after expiration and deletes the key' do
      timed_hash[:foo] = 'bar'
      sleep expires_in + 0.05
      expect(timed_hash[:foo]).to be_nil
      expect(timed_hash.size).to eq(0)
    end
  end

  describe '#size' do
    it 'returns the number of unexpired keys' do
      timed_hash[:foo] = 'bar'
      timed_hash[:baz] = 'qux'
      expect(timed_hash.size).to eq(2)
      sleep expires_in + 0.05
      expect(timed_hash.size).to eq(0)
    end
  end

  describe '#clear' do
    it 'removes all keys' do
      timed_hash[:foo] = 'bar'
      timed_hash[:baz] = 'qux'
      timed_hash.clear
      expect(timed_hash.size).to eq(0)
      expect(timed_hash[:foo]).to be_nil
      expect(timed_hash[:baz]).to be_nil
    end
  end

  describe 'thread safety' do
    it 'handles concurrent access' do
      threads = []
      10.times do |i|
        threads << Thread.new { timed_hash[i] = i }
      end
      threads.each(&:join)
      expect(timed_hash.size).to eq(10)
      10.times do |i|
        expect(timed_hash[i]).to eq(i)
      end
    end
  end
end
