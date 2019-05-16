require 'tinyci/subprocesses'
require 'tinyci/git_utils'
require 'tinyci/logging'
require 'tinyci/config'

require 'tinyci/builders/test_builder'
require 'tinyci/testers/test_tester'

require 'tinyci/builders/script_builder'
require 'tinyci/testers/script_tester'
require 'tinyci/hookers/script_hooker'

require 'fileutils'

module TinyCI
  # Responsible for managing the running of TinyCI against a single git object.
  # 
  # @attr builder [TinyCI::Executor] Returns the Builder object. Used solely for testing at this time.
  # @attr tester [TinyCI::Executor] Returns the Tester object. Used solely for testing at this time.
  class Runner
    include Subprocesses
    include GitUtils
    include Logging
    
    attr_accessor :builder, :tester, :hooker
    
    # Constructor, allows injection of generic configuration params.
    # 
    # @param working_dir [String] The working directory to execute against.
    # @param commit [String] SHA1 of git object to run against
    # @param logger [Logger] Logger object
    # @param time [Time] Override time of object creation. Used solely for testing at this time.
    # @param config [Hash] Override TinyCI config object, normally loaded from `.tinyci` file. Used solely for testing at this time.
    def initialize(working_dir: '.', commit:, time: nil, logger: nil, config: nil)
      @working_dir = working_dir
      @logger = logger
      @config = config
      @commit = commit
      @time = time || commit_time
    end
    
    # Runs the TinyCI system against the single git object referenced in `@commit`.
    # 
    # @return [Boolean] `true` if the commit was built and tested successfully, `false` otherwise
    def run!
      begin
        ensure_path target_path
        setup_log
        
        log_info "Commit: #{@commit}"
        
        log_info "Cleaning..."
        clean
        
        log_info "Exporting..."
        ensure_path export_path
        export
        
        begin
          load_config
        rescue ConfigMissingError => e
          log_error e.message
          log_error 'Removing export...'
          clean
          
          return false
        end
        @builder ||= instantiate_builder
        @tester  ||= instantiate_tester
        @hooker  ||= instantiate_hooker
        
        log_info "Building..."
        run_hook! :before_build
        begin
          @builder.build
        rescue => e
          run_hook! :after_build_failure
          
          raise e if ENV['TINYCI_ENV'] == 'test'
          
          log_error e
          log_debug e.backtrace
          
          return false
        else
          run_hook! :after_build_success
        ensure
          run_hook! :after_build
        end
        
        
        log_info "Testing..."
        run_hook! :before_test
        begin
          @tester.test
        rescue => e
          run_hook! :after_test_failure
          
          raise e if ENV['TINYCI_ENV'] == 'test'
          
          log_error e
          log_debug e.backtrace
          
          return false
        else
          run_hook! :after_test_success
        ensure
          run_hook! :after_test
        end
        
        
        
        log_info "Finished #{@commit}"
      rescue => e
        raise e if ENV['TINYCI_ENV'] == 'test'
        
        log_error e
        log_debug e.backtrace
        return false
      end
      
      true
    end
    
    # Build the absolute target path
    def target_path
      File.absolute_path("#{@working_dir}/builds/#{@time.to_i}_#{@commit}/")
    end
    
    # Build the export path
    def export_path
      File.join(target_path, 'export')
    end
    
    private
    
    def run_hook!(name)
      return unless @hooker
      
      @hooker.send("#{name}!")
    end
    
    # Creates log file if it doesnt exist
    def setup_log
      return unless @logger.is_a? MultiLogger
      FileUtils.touch logfile_path
      @logger.output_path = logfile_path
    end
    
    def logfile_path
      File.join(target_path, 'tinyci.log')
    end
    
    # Instantiate the Builder object according to the class named in the config
    def instantiate_builder
      klass = TinyCI::Builders.const_get(@config[:builder][:class])
      klass.new(@config[:builder][:config].merge(target: export_path, commit: @commit), logger: @logger)
    end
    
    # Instantiate the Tester object according to the class named in the config
    def instantiate_tester
      klass = TinyCI::Testers.const_get(@config[:tester][:class])
      klass.new(@config[:tester][:config].merge(target: export_path, commit: @commit), logger: @logger)
    end
    
    # Instantiate the Hooker object according to the class named in the config
    def instantiate_hooker
      return nil unless @config[:hooker].is_a? Hash
      
      klass = TinyCI::Hookers.const_get(@config[:hooker][:class])
      klass.new(@config[:hooker][:config].merge(target: export_path, commit: @commit), logger: @logger)
    end
    
    # Instantiate the {Config} object from the `.tinyci.yml` file in the exported directory
    def load_config
      @config ||= Config.new(working_dir: export_path)
    end

    # Parse the commit time from git
    def commit_time
      Time.at execute(git_cmd('show', '-s', '--format=%ct', @commit)).to_i
    end

    # Ensure a path exists
    def ensure_path(path)
      execute 'mkdir', '-p', path
    end
    
    # Delete the export path
    def clean
      FileUtils.rm_rf export_path
    end

    # Export a clean copy of the repo at the given commit, without a .git directory etc.
    # This implementation is slightly hacky but its the cleanest way to do it in the absence of
    # a `git export` subcommand.
    # see https://stackoverflow.com/a/163769
    def export
      execute_pipe git_cmd('archive', '--format=tar', @commit), ['tar', '-C', export_path, '-xf', '-']
    end
  end
end
