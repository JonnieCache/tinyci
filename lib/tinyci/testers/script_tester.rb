# frozen_string_literal: true

require 'tinyci/executor'

module TinyCI
  module Testers
    class ScriptTester < TinyCI::Executor
      def test
        execute_stream(command, label: 'test', pwd: @config[:export])
      end
    end
  end
end
