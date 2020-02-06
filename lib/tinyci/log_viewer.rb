# frozen_string_literal: true

require 'tinyci/path_utils'
require 'file-tail'

module TinyCI
  class LogViewer
    include PathUtils

    def initialize(opts)
      @working_dir = opts[:working_dir]
      @commit = opts[:commit]
      @follow = opts[:follow]
      @num_lines = opts[:num_lines]
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
  end
end
