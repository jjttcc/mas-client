
# Test oracle for daily MACD Crossover Buy analysis on IBM
class MACD_CrossoverBuyOracle
  public

  attr_reader :start_date, :end_date, :symbol

  def selected_analyzer(analyzers)
    result = nil
    matches = analyzers.select do |a|
      a.name =~ /MACD\s*Crossover\s*.?Buy/
    end
    if matches.count > 0 then
      result = matches[0]
    end
    result
  end

  def selected_analyzers(analyzers, expr)
    analyzers.select do |a|
      a.name =~ /#{expr}/i
    end
  end

  def expected_count; @dates.count end

  def parameter_settings
    "1:5,2:13,3:5,4:13,5:6"
  end

  def results_correct(data)
    result = true
    i=0
    while result && i < data.count do
      result = data[i].analyzer.name == @event_name &&
        data[i].event_type_id == @type_id &&
        data[i].datetime == @dates[i]
      i += 1
    end
    result
  end

  # Are the expected results contained, in the right order, in 'data'?
  def results_fuzzily_correct(data)
    result = true
    i=0; j = 0; hitcount = 0
    while j < @dates.count do
      while i < data.count do
        if
          data[i].analyzer.name == @event_name &&
            data[i].event_type_id == @type_id &&
            data[i].datetime == @dates[j]
        then
          hitcount += 1
          break
        end
        i += 1
      end
      j += 1
    end
    result = hitcount == @dates.count
  end

  private

  def initialize
    @start_date = DateTime.new(2016, 1, 1)
    @end_date   = DateTime.new(2017, 12, 30)
    @event_name = 'MACD Crossover (Buy)'
    @type_id    = 'b'
    @mydate     = DateTime.new(2016, 1, 28)
    @dates      = initialized_dates
    @symbol     = 'ibm'
  end

  def initialized_dates
    result = []
    result << DateTime.new(2016, 1, 28)
    result << DateTime.new(2016, 2, 17)
    result << DateTime.new(2016, 3, 2)
    result << DateTime.new(2016, 3, 11)
    result << DateTime.new(2016, 3, 16)
    result << DateTime.new(2016, 4, 1)
    result << DateTime.new(2016, 4, 15)
    result << DateTime.new(2016, 4, 26)
    result << DateTime.new(2016, 5, 6)
    result << DateTime.new(2016, 5, 24)
    result << DateTime.new(2016, 6, 20)
    result << DateTime.new(2016, 6, 30)
    result << DateTime.new(2016, 7, 22)
    result << DateTime.new(2016, 8, 8)
    result << DateTime.new(2016, 9, 1)
    result << DateTime.new(2016, 9, 21)
    result << DateTime.new(2016, 10, 26)
    result << DateTime.new(2016, 11, 28)
    result << DateTime.new(2016, 12, 7)
    result << DateTime.new(2017, 1, 4)
    result << DateTime.new(2017, 1, 20)
    result << DateTime.new(2017, 2, 9)
    result << DateTime.new(2017, 3, 28)
    result << DateTime.new(2017, 4, 17)
    result << DateTime.new(2017, 4, 27)
    result << DateTime.new(2017, 5, 15)
    result << DateTime.new(2017, 6, 8)
    result << DateTime.new(2017, 6, 28)
    result << DateTime.new(2017, 7, 13)
    result << DateTime.new(2017, 8, 1)
    result << DateTime.new(2017, 8, 22)
    result << DateTime.new(2017, 9, 11)
    result << DateTime.new(2017, 9, 26)
    result << DateTime.new(2017, 10, 3)
    result << DateTime.new(2017, 10, 9)
    result << DateTime.new(2017, 10, 18)
    result << DateTime.new(2017, 11, 17)
    result << DateTime.new(2017, 12, 12)
    result << DateTime.new(2017, 12, 28)
    result
  end

end
