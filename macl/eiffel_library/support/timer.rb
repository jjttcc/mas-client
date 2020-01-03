# Facilities for timing execution";
class Timer

creation

  make

private

  make
      # Initialize and start the timer.
    do
      create start_time.make_now
    end

  public

  ##### Access

  start_time: DATE_TIME
      # Time when `start' was called

  current_time: DATE_TIME
      # The current time
    do
      create Result.make_now
    end

  elapsed_time: DATE_TIME_DURATION
      # Amount of time that has elapsed since `start' was called.
    do
      Result := current_time.duration - start_time.duration
      # DATE_TIME_DURATION requires origin to be set.
      Result.set_origin_date_time (
        create {DATE_TIME}.make_by_date (create {DATE}.make (1, 1, 1)))
    end

##### Basic operations

  start
      # Start the timer.
    do
      start_time.make_now
    end

end
