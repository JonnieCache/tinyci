# frozen_string_literal: true

require 'tinyci/path_utils'
require 'tinyci/git_utils'
require 'file-tail'

module TinyCI
  # For reviewing the log files created by tinyCI runs. Can print lines from either a specific
  # commit's logfile, or from the global logfile. Has functionality similar to the coreutils `tail`
  # command.
  class LogViewer
    include PathUtils
    include GitUtils

    #
    # Constructor
    #
    # @param [<Type>] working_dir  The directory from which to run.
    # @param [<Type>] commit The commit to run against
    # @param [<Type>] follow After printing, instead of exiting, block and wait for additional data to be appended be the file and print it as it
    #   is written. Equivalent to unix `tail -f`
    # @param [<Type>] num_lines How many lines of the file to print, starting from the end.
    # Equivalent to unix `tail -n`
    #
    def initialize(working_dir:, commit: nil, follow: false, num_lines: nil)
      @working_dir = working_dir
      @commit = commit
      @follow = follow
      @num_lines = num_lines
    end

    def view!
      if @follow
        tail
      else
        dump
      end
    end

    private

    def dump
      unless inside_repository?
        warn 'Error: Not currently inside a git repo, or not on a branch'
        return false
      end

      unless logfile_exists?
        warn "Error: Logfile does not exist at #{logfile_to_read}"
        warn "Did you mean \e[1mtinyci --remote #{current_tracking_remote} log\e[22m?"
        return false
      end

      if @num_lines.nil?
        puts File.read(logfile_to_read)
      else
        File.open(logfile_to_read) do |log|
          log.extend File::Tail
          log.return_if_eof = true
          log.backward @num_lines if @num_lines
          log.tail { |line| puts line }
        end
      end
    end

    def tail
      File.open(logfile_to_read) do |log|
        log.extend(File::Tail)

        log.backward @num_lines if @num_lines
        log.tail { |line| puts line }
      end
    end

    def logfile_to_read
      if @commit
        logfile_path
      else
        repo_logfile_path
      end
    end

    def logfile_exists?
      File.exist? logfile_to_read
    end
  end
end
