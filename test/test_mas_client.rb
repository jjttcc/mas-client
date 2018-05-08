require 'ruby_contracts'
require 'minitest/autorun'
require_relative './test_setup'
require_relative './analyzer_test.rb'
require_relative './assorted_tests.rb'
require_relative './data_test.rb'
require_relative './indicator_test.rb'
require_relative './parameter_test.rb'

class AnalyzerTestChild < AnalyzerTest
end

class DataTestChild < DataTest
end

class DataTestChild < DataTest
end

class IndicatorTestChild < IndicatorTest
end

class ParameterTestChild < ParameterTest
end

