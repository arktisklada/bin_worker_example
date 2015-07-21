require "rails_helper"

RSpec.describe Worker do
  describe "#start" do
    it "does what we want it to" do
      stub_kernel_loop

      Worker.new.start

      # Expectations for what we're doing in the while loop
    end

    it "loops by the sleep delay" do
      stub_kernel_loop

      Worker.new.start

      expect(Worker::SLEEP_DELAY).to have_received(:times)
    end

    it "sleeps between loop iterations" do
      stub_kernel_loop

      Worker.new.start

      expect(Kernel).to have_received(:sleep).with(1)
    end

    def stub_kernel_loop
      allow(Kernel).to receive(:loop) do |&block|
        block.call
      end

      allow(Worker::SLEEP_DELAY).to receive(:times) do |&block|
        block.call
      end

      allow(Kernel).to receive(:sleep)
    end
  end
end
