# frozen_string_literal: true

RSpec.describe Outhad::Integrations::Core::RateLimiter do
  let(:sync_config) { instance_double("SyncConfig", stream: stream) }
  let(:stream) do
    instance_double("Stream",
                    request_rate_limit: 4,
                    rate_limit_unit_seconds: 1,
                    name: "stream_name")
  end
  let(:records) { %w[record1 record2] }

  let(:limiter_class) do
    Class.new do
      prepend Outhad::Integrations::Core::RateLimiter

      define_method(:write) do |sync_config, _records, _action = "destination_insert"|
        Outhad::Integrations::Service.logger.info("write called: stream_name: #{sync_config.stream.name}")
      end
    end.new
  end

  describe "#write" do
    it "should set the @queue and call super on calling write" do
      expected_message = "write called: stream_name: #{sync_config.stream.name}"
      expect(Outhad::Integrations::Service.logger).to receive(:info).with(expected_message)

      limiter_class.write(sync_config, records)

      queue = limiter_class.instance_variable_get(:@queue)
      expect(queue).not_to be_nil
      expect(queue).to be_a(Limiter::RateQueue)

      expect(queue.instance_variable_get(:@size)).to eq(stream.request_rate_limit)
      expect(queue.instance_variable_get(:@interval)).to eq(stream.rate_limit_unit_seconds)
    end

    it "should set the @queue once and call super N times on calling write N times" do
      expected_message = "write called: stream_name: #{sync_config.stream.name}"
      expect(Outhad::Integrations::Service.logger).to receive(:info).with(expected_message).exactly(10).times
      expect(Outhad::Integrations::Service.logger).to receive(:info).with(match(/Hit the limit for stream/)).exactly(2).times
      10.times { limiter_class.write(sync_config, records) }
    end
  end
end
