require 'tinyci/subprocesses'
require 'tinyci/logging'
require 'ostruct'
require 'erb'

module TinyCI
  # Parent class for Builder and Tester classes
  # 
  # @abstract
  class Executor
    include Subprocesses
    include Logging
    
    # Returns a new instance of the executor.
    # 
    # @param config [Hash] Configuration hash, typically taken from relevant key in the {Config} object.
    # @param logger [Logger] Logger object
    def initialize(config, logger: nil)
      @config = config
      @logger = logger
    end
    
    def command
      ['/bin/sh', '-c', "'#{interpolated_command}'"]
    end
    
    private
    
    def interpolated_command
      src = @config[:command]
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
