# API monitor service



## The Fact

We are dependent on an external API with continuous connectivity.

## The Problem

That API occasionally goes down and is not as stable as we'd like (i.e. < 100%).

## The Solution

Notify customers BEFORE they contact us and manage expectations.

## The Implementation

A worker service that monitors this API on a given interval, and provides status updates to admins and account representatives.

---

## Worker class

This class wraps our API monitoring processes with an endless loop

### Step 1

let's create that loop.  2 minutes between "pings" sounds good.

```ruby
class Worker
  SLEEP_DURATION = 2.minutes

  def start
    puts "Staring API status service..."

    loop do
      # Perform API actions here

      sleep(SLEEP_DURATION)
    end
  end
end
```

### Step 2

Because ending gracefully is nice:

```ruby
class Worker
  SLEEP_DELAY = 2.minutes
  SLEEP_DURATION = 1.second

  def start
    puts "Staring API status service..."

    trap("TERM") do
      Thread.new { puts "Exiting..." }
      stop
    end

    trap("INT") do
      Thread.new { puts "Exiting..." }
      stop
    end

    loop do
      # Perform API actions here

      sleep(SLEEP_DURATION)

      break if stop?
    end
  end

  private

  def stop
    @exit = true
  end

  def stop?
    @exit == true
  end
end

```

### Step 3

Wait, 2 minutes before we can end gracefully?!?  Let's pull it all together:

```ruby
class Worker
  SLEEP_DELAY = 2.minutes
  SLEEP_DURATION = 1.second

  def start
    log "Staring API status service..."

    bind_signal_traps

    Kernel.loop do
      # Perform API actions here

      SLEEP_DELAY.times do
        if stop?
          break
        end
        Kernel.sleep(SLEEP_DURATION)
      end

      if stop?
        break
      end
    end
  end

  private

  def stop
    @exit = true
  end

  def stop?
    @exit == true
  end

  def bind_signal_traps
    trap("TERM") do
      Thread.new { log "Exiting..." }
      stop
    end

    trap("INT") do
      Thread.new { log "Exiting..." }
      stop
    end
  end

  def log(message)
    Rails.logger.info(message)
  end
end

```

**Note:**

Calling `loop` and `sleep` on `Kernel` allows those methods to be testable.

---

## Worker class spec

Test yo classes!

```ruby
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
```

---

## Rake task

A simple rake task that creates our class and starts the worker activity:

```ruby
namespace :api do
  task status: [:environment] do
    Worker.new.start
  end
end
```

---

## Binary

Sure, we could just say `rake api:status` but it needs to be run on a remote server as a daemon or standalone service.  The executable:

### Step 1

Launch that rake task

```sh
#!/bin/sh

bundle exec rake api:status
```

### Environment support

#### Modification 1

Do we want to run this rake task in development?  No.  Because rate limits and resources and stuff.

```sh
#!/bin/sh

if [ "$RACK_ENV" != "development" ]; then
  bundle exec rake api:status
else
  echo "Skipping api service in development!!"
fi

```

#### Modification 2

Anyone use `foreman start`?  Yet another endless while loop... but with minimal CPU

```sh
#!/bin/sh

if [ "$RACK_ENV" != "development" ]; then
  bundle exec rake api:status
else
  echo "Skipping api service in development!!"
  while(true)
  do
    sleep 60m # limits CPU usage
  done
fi

```

---

## Links

[Github project](https://github.com/arktisklada/bin_worker_example)