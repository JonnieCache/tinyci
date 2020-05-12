# frozen_string_literal: true

require 'tinyci/subprocesses'
require 'git_clone_url'

module TinyCI
  # Methods for dealing with git repos.
  module GitUtils
    # Returns the absolute path to the root of the current git directory
    #
    # @return [String] the path
    def repo_root
      return git_directory_path if inside_bare_repo?

      if inside_git_directory?
        File.expand_path('..', git_directory_path)
      elsif inside_work_tree?
        execute(git_cmd('rev-parse', '--show-toplevel'))
      else
        raise 'not in git directory or work tree!?'
      end
    end

    # Are we currently under a git repo?
    def inside_git_directory?
      execute(git_cmd('rev-parse', '--is-inside-git-dir')) == 'true'
    end

    # Are we under a bare repo?
    def inside_bare_repo?
      execute(git_cmd('rev-parse', '--is-bare-repository')) == 'true'
    end

    # Are we currently under a git work tree?
    def inside_work_tree?
      execute(git_cmd('rev-parse', '--is-inside-work-tree')) == 'true'
    end

    # Are we currently under a repo in any sense?
    def inside_repository?
      cmd = git_cmd('rev-parse', '--is-inside-work-tree', '--is-inside-git-dir')
      execute(cmd).split.any? { |s| s == 'true' }
    end

    # Returns the absolute path to the .git directory
    def git_directory_path
      base = defined?(@working_dir) ? @working_dir.to_s : nil

      File.expand_path(execute(git_cmd('rev-parse', '--git-dir')), base)
    end

    # Does the specified file exist in the repo at the specified revision
    def file_exists_in_git?(path, ref = @commit)
      cmd = git_cmd('cat-file', '-e', "#{ref}:#{path}")

      execute_and_return_status(cmd).success?
    end

    # Does the given sha exist in this repo's history?
    def commit_exists?(commit = @commit)
      cmd = git_cmd('cat-file', '-e', commit)

      execute_and_return_status(cmd).success?
    end

    # Does the repo have a commit matching the given name?
    def remote_exists?(remote = @remote)
      execute(git_cmd('remote')).split("\n").include? remote
    end

    # Get the url for a given remote
    # Alias for #push_url
    def remote_url(remote = @remote)
      push_url remote
    end

    # Does the given remote point to github?
    def github_remote?(remote = @remote)
      remote_url(remote).host == 'github.com'
    end

    # Does the given remote point to an ssh url?
    def ssh_remote?(remote = @remote)
      remote_url(remote).is_a? URI::SshGit::Generic
    end

    # Return the upstream remote for the current branch
    def current_tracking_remote
      full = execute git_cmd 'rev-parse', '--symbolic-full-name', '--abbrev-ref', '@{push}'
      full.split('/')[0]
    rescue TinyCI::Subprocesses::SubprocessError => e
      log_error 'Current branch does not have an upstream remote' if e.status.exitstatus == 128
    end

    # The current HEAD branch
    def current_branch
      execute git_cmd 'rev-parse', '--abbrev-ref', 'HEAD'
    end

    # The push url for the specified remote, parsed into a `URI` object
    def push_url(remote = @remote)
      url = raw_push_url(remote)
      GitCloneUrl.parse url
    rescue URI::InvalidComponentError
      URI.parse url
    end

    # Parse the commit time from git
    def time
      @time ||= Time.at execute(git_cmd('show', '-s', '--format=%at', @commit)).to_i
    end

    # Execute a git command, passing the -C parameter if the current object has
    # the working_directory instance var set
    def git_cmd(*args)
      cmd = ['git']
      cmd += ['-C', @working_dir.to_s] if defined?(@working_dir) && !@working_dir.nil?
      cmd += args

      cmd
    end

    # Get push url as a string. Not intended to be called directly, instead call {#push_url}
    def raw_push_url(remote = @remote)
      @push_urls ||= {}
      @push_urls[remote] ||= execute git_cmd 'remote', 'get-url', '--push', remote
    end

    def self.included(base)
      base.include Subprocesses
    end

    def self.extended(base)
      base.extend Subprocesses
    end
  end
end
