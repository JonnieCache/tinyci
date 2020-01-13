# frozen_string_literal: true

require 'tinyci/runner'
require 'tinyci/subprocesses'
require 'tinyci/git_utils'
require 'pidfile'

module TinyCI
  # Manages the execution of test jobs. Responsible for deciding which
  # commits need to be built and tested. Also manages the pidfile. This
  # is the main entrypoint for TinyCI.
  #
  # @attr_reader [String] working_dir The working directory to execute against
  class Scheduler
    include Subprocesses
    include Logging
    include GitUtils

    attr_reader :working_dir

    # Constructor, allows injection of configuration and custom {Runner} class.
    # Config params are passed to {Runner} instances.
    #
    # @param working_dir [String] The working directory to execute against
    # @param logger [Logger] Logger object
    # @param commit [String] specific git object to run against
    # @param runner_class [TinyCI::Runner] Injection of {Runner} dependency
    def initialize(
      working_dir: nil,
      logger: nil,
      commit: nil,
      runner_class: Runner
    )

      @working_dir = working_dir || repo_root
      @logger = logger
      @runner_class = runner_class
      @commit = commit
    end

    # Runs the TinyCI system against the relevant commits. Also sets up the pidfile.
    #
    # @return [Boolean] `true` if all commits built and tested successfully, `false` otherwise
    def run!
      pid = PidFile.new(pidfile: 'tinyci.pid', piddir: @working_dir)

      result = if @commit
                 run_commit get_commit @commit
               else
                 run_all_commits
               end

      pid.release

      result
    end

    private

    # Git objects to be executed against, all those without a tinyci tag
    #
    # @return [Array<String>] the sha1 hashes in reverse order of creation time
    def retrieve_commits
      log = execute(git_cmd('log', '--notes=tinyci*', '--format=%H %ct %N§§§', '--reverse'))
      lines = log.split('§§§')

      lines.map { |l| format_commit_data(l) }.select { |c| c[:result].nil? }
    end

    def get_commit(sha)
      data = execute(git_cmd('show', '--quiet', '--notes=tinyci*', '--format=%H %ct', sha))

      format_commit_data(data)
    end

    # Instantiates {Runner} for a given git object, runs it, and stores the result
    def run_commit(commit)
      result = @runner_class.new(
        working_dir: @working_dir,
        commit: commit[:sha],
        time: commit[:time],
        logger: @logger
      ).run!

      set_result(commit, result)
    end

    def format_commit_data(data)
      parts = data.split(' ')
      {
        sha: parts[0],
        time: parts[1],
        result: parts[2]
      }
    end

    # Repeatedly gets the list of eligable commits and runs TinyCI against them until there are no more remaining
    def run_all_commits
      commits = retrieve_commits

      until commits.empty?
        commits.each { |c| run_commit(c) }

        commits = retrieve_commits
      end
    end

    # Stores the result in a git note
    def set_result(commit, result)
      result_message = result ? 'success' : 'failure'

      execute git_cmd('notes', '--ref', 'tinyci-result', 'add', '-m', result_message, commit[:sha])
    end
  end
end
