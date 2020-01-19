
# Facilities for timing execution";
class Timer

  private

  # Initialize and start the timer.
  def initialize
    @start_time = Time.now
  end

  public

  ##### Access

  # Time when `start' was called
  attr_reader :start_time

  # The current time
  def current_time
    Time.now
  end

  # Number of seconds that has elapsed since `start' was called.
  def elapsed_time
    result = current_time.to_i - start_time.to_i
  end

  ##### Basic operations

  # Start the timer.
  def start
    @start_time = Time.now
  end

end
