# frozen_string_literal: true

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
    # @param config [Hash] Configuration hash, typically taken
    # from relevant key in the {Config} object.
    def initialize(config)
      @config = config
      @logger = config[:logger]
    end

    def command
      ['/bin/sh', '-c', "'#{interpolate(@config[:command])}'"]
    end

    private

    def interpolate(command)
      erb = ERB.new command

      erb.result(erb_scope)
    end

    def template_vars
      OpenStruct.new(
        commit: @config[:commit],
        export: @config[:export],
        target: @config[:target]
      )
    end

    def erb_scope
      template_vars.instance_eval { binding }
    end
  end
end
