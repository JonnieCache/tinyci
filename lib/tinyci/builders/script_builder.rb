require 'tinyci/executor'

module TinyCI
  module Builders
    class ScriptBuilder < TinyCI::Executor
      def build
        execute_stream(command, label: 'build', pwd: @config[:export])
      end
    end
  end
end
