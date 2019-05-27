require 'logger'

module TinyCI
  # This class allows logging to both `STDOUT` and to a file with a single call.
  # @attr [Boolean] quiet Disables logging to STDOUT
  class MultiLogger
    FORMAT = Proc.new do |severity, datetime, progname, msg|
      "[#{datetime.strftime "%T"}] #{msg}\n"
    end
    
    LEVEL = Logger::INFO
    
    attr_accessor :quiet
    
    # Constructor
    # 
    # @param [Boolean] quiet Disables logging to STDOUT
    # @param [String] path Location to write logfile to
    def initialize(quiet: false, path: nil)
      @file_logger = nil
      self.output_path = path
      @quiet = quiet
      
      @stdout_logger = Logger.new($stdout)
      @stdout_logger.formatter = FORMAT
      @stdout_logger.level = LEVEL
    end
    
    def targets
      logs = []
      logs << @file_logger if @file_logger
      logs << @stdout_logger unless @quiet
      
      logs
    end
    
    def output_path=(path)
      if path
        @file_logger = Logger.new(path)
        @file_logger.formatter = FORMAT
        @file_logger.level = LEVEL
      end
    end

    %w(log debug info warn error fatal unknown).each do |m|
      define_method(m) do |*args|
        targets.each { |t| t.send(m, *args) }
      end
    end
  end
end
