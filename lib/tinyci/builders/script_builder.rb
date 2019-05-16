require 'tinyci/executor'
require 'ostruct'
require 'erb'

module TinyCI
  module Builders
    class ScriptBuilder < TinyCI::Executor
      def build
        execute_stream(interpolated_command, label: 'build', pwd: @config[:target])
      end

      private

      def interpolated_command
        src = script_location.join(' ')
        erb = ERB.new src
        
        erb.result(erb_scope)
      end
      
      def template_vars
        OpenStruct.new(commit: @config[:commit])
      end

      def erb_scope
        template_vars.instance_eval { binding }
      end
    end
  end
end
