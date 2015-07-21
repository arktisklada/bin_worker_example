class Worker
  SLEEP_DELAY = 2.minutes
  SLEEP_DURATION = 1.second

  def start
    log "Staring API status service..."

    bind_signal_traps

    Kernel.loop do
      # Perform actions here

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
