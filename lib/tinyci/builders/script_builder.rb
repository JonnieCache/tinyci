require 'tinyci/executor'

module TinyCI
  module Builders
    class ScriptBuilder < TinyCI::Executor
      def build
        execute_stream(script_location, label: 'build', pwd: @config[:target])
      end
      
      private
      
      def script_location
        File.join @config[:target], @config[:command]
      end
      
    end
  end
end
