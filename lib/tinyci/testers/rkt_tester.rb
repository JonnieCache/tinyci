require 'tinyci/executor'

module TinyCI
  module Testers
    class RktTester < TinyCI::Executor
      def test
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
          set_env,
          '--exec',
          @config[:command]
        ].flatten
        
        log_info "RKT test command: #{cmd.join(' ')}"
        
        execute_stream(*cmd, label: 'test')
        
      end
      
      private
      
      def set_env
        return [] if @config[:env].nil?
        
        @config[:env].map {|k,v| "--set-env=#{k.upcase}=#{v}"}
      end
    end
  end
end
