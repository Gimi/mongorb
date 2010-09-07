require 'rubygems'
require 'minitest/unit'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'mongorb'

begin
  require_relative 'models'
rescue
  require 'models'
end

class MiniTest::Unit::TestCase
  class << self
    def setup(&block)
      define_method "setup", &block
    end

    def test(something, &block)
      define_method "test_#{something}", &block
    end
  end
end

MiniTest::Unit.autorun
