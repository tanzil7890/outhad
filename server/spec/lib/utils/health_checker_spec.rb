# frozen_string_literal: true

require "rails_helper"

RSpec.describe Utils::HealthChecker do
  describe ".run" do
    let(:port) { 9999 } # Using a non-standard port to avoid conflicts

    before do
      ENV["OUTHAD_WORKER_HEALTH_CHECK_PORT"] = port.to_s
      described_class.run
      sleep 1 # Give the server a moment to start
    end

    after do
      # Send an INT signal to shut down the server
      Process.kill("INT", Process.pid)
      sleep 1 # Give the server a moment to shut down
    end

    it "responds to /health with a success message" do
      response = Net::HTTP.get_response(URI("http://localhost:#{port}/health"))
      expect(response.body).to eq("Service is healthy")
      expect(response.code).to eq("200")
    end
  end
end
