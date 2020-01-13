# frozen_string_literal: true

require 'tinyci/multi_logger'

module TinyCI
  # Defines helper instance methods for logging to reduce code verbosity
  module Logging
    %w[log debug info warn error fatal unknown].each do |m|
      define_method("log_#{m}") do |*args|
        return false unless defined?(@logger) && @logger.is_a?(MultiLogger)

        @logger.send(m, *args)
      end
    end
  end
end
