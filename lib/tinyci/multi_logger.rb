# frozen_string_literal: true

require 'logger'
require 'fileutils'

module TinyCI
  # This class allows logging to both `STDOUT` and to a file with a single call.
  # @attr [Boolean] quiet Disables logging to STDOUT
  class MultiLogger
    FORMAT = proc do |_severity, datetime, _progname, msg|
      "[#{datetime.strftime '%T'}] #{msg}\n"
    end

    LEVEL = Logger::INFO

    attr_accessor :quiet

    # Constructor
    #
    # @param [Boolean] quiet Disables logging to STDOUT
    # @param [String] path Location to write logfile to
    def initialize(quiet: false, path: nil, paths: [])
      @file_loggers = []
      add_output_path path
      paths.each { |p| add_output_path(p) }
      @quiet = quiet

      @stdout_logger = Logger.new($stdout)
      @stdout_logger.formatter = FORMAT
      @stdout_logger.level = LEVEL
    end

    def targets
      logs = []
      logs += @file_loggers
      logs << @stdout_logger unless @quiet

      logs
    end

    def add_output_path(path)
      return unless path

      FileUtils.touch path

      logger = Logger.new(path)
      logger.formatter = FORMAT
      logger.level = LEVEL
      @file_loggers << logger

      logger
    end

    %w[log debug info warn error fatal unknown].each do |m|
      define_method(m) do |*args|
        targets.each { |t| t.send(m, *args) }
      end
    end
  end
end
