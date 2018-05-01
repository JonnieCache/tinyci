require 'tinyci/executor'

module TinyCI
  module Testers
    class ScriptTester < TinyCI::Executor
      def test
        execute_stream(script_location, label: 'test', pwd: @config[:target])
      end
      
      private
      
      def script_location
        File.join @config[:target], @config[:command]
      end
      
    end
  end
end
