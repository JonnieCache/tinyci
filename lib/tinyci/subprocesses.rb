# frozen_string_literal: true

require 'open3'
require 'English'
require 'tinyci/logging'

module TinyCI
  # Methods for executing subprocesses in various ways and collecting the results.
  module Subprocesses
    # Synchronously execute a command as a subprocess and return the output.
    #
    # @param [Array<String>] command The command line
    # @param [String] label A label for debug and logging purposes
    #
    # @return [String] The output of the command
    # @raise [SubprocessError] if the subprocess returns status > 0
    def execute(*command, label: nil)
      stdout, stderr, status = Open3.capture3(*command.flatten)

      log_debug caller[0]
      log_debug "CMD: #{command.join(' ')}"
      log_debug "OUT: #{stdout}"
      log_debug "ERR: #{stderr}"

      unless status.success?
        log_error stdout
        log_error stderr
        raise SubprocessError.new(label, command.join(' '), status)
      end

      stdout.chomp
    end

    # Synchronously execute a chain multiple commands piped into each other as a
    # subprocess and return the output.
    #
    # @param [Array<Array<String>>] commands The command lines
    # @param [String] label A label for debug and logging purposes
    #
    # @return [String] The output of the command
    # @raise [SubprocessError] if the subprocess returns status > 0
    def execute_pipe(*commands, label: nil)
      stdout, waiters = Open3.pipeline_r(*commands)
      output = stdout.read

      waiters.each_with_index do |waiter, i|
        status = waiter.value
        unless status.success?
          log_error output
          raise SubprocessError.new(label, commands[i].join(' '), status)
        end
      end

      output.chomp
    end

    # Synchronously execute a command as a subprocess and and stream the output
    # to `STDOUT`
    #
    # @param [Array<String>] command The command line
    # @param [String] label A label for debug and logging purposes
    # @param [String] pwd Optionally specify a different working directory in which to execute the command
    #
    # @return [TrueClass] `true` if the command executed successfully
    # @raise [SubprocessError] if the subprocess returns status > 0
    def execute_stream(*command, label: nil, pwd: nil)
      opts = {}
      opts[:chdir] = pwd unless pwd.nil?

      log_debug "CMD: #{command.join(' ')}"

      Open3.popen2e(command.join(' '), opts) do |stdin, stdout_and_stderr, wait_thr|
        stdin.close

        until stdout_and_stderr.closed? || stdout_and_stderr.eof?
          line = stdout_and_stderr.gets
          log_info line.chomp
          $stdout.flush
        end

        unless wait_thr.value.success?
          raise SubprocessError.new(label, command.join(' '), wait_thr.value)
        end

      ensure
        stdout_and_stderr.close
      end

      true
    end

    def execute_and_return_status(command)
      system(*command, out: File::NULL, err: File::NULL)

      $CHILD_STATUS
    end

    # An error raised when any of the {Subprocesses} methods fail
    #
    # @attr_reader [Integer] status The return code of the process
    # @attr_reader [String] command The command used to spawn the process
    class SubprocessError < RuntimeError
      attr_reader :status
      attr_reader :command

      def initialize(label, command, status, message = "#{label}: `#{command}` failed with status #{status.exitstatus}")
        @status = status
        @command = command
        super(message)
      end
    end

    def self.included(base)
      base.include TinyCI::Logging
    end

    def self.extended(base)
      base.extend TinyCI::Logging
    end
  end
end
