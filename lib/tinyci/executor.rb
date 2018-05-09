require 'tinyci/subprocesses'
require 'tinyci/logging'

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
    
    private
    
    def script_location
      # path = File.join @config[:target], @config[:command]
      ['/bin/sh', '-c', "'#{@config[:command]}'"]
    end
  end
end
