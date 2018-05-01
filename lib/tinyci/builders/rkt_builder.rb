require 'tinyci/executor'

module TinyCI
  module Builders
    class RktBuilder < TinyCI::Executor
      def build
        cmd = [
          'sudo',
          'rkt',
          'run',
          '--net=host',
          '--insecure-options=image',
          '--volume',
          "src,kind=host,source=#{@config[:target]}/src,readOnly=false",
          '--mount',
          "volume=src,target=#{@config[:src_path]}",
          @config[:image],
          '--working-dir',
          @config[:src_path],
          '--exec',
          @config[:command]
        ]
        
        log_info "RKT build command: #{cmd.join(' ')}"
        
        execute_stream(*cmd, label: 'build')
      end
      
    end
  end
end
