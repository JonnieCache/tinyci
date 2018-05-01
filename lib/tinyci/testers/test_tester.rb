require 'tinyci/executor'

module TinyCI
  module Testers
    class TestTester < TinyCI::Executor
      def test
        raise 'Simulated test failed' if @config[:result] == false
      end
    end
  end
end
