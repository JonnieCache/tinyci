# frozen_string_literal: true

require 'tinyci/subprocesses'

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

    def file_exists_in_git?(path, ref = @commit)
      cmd = git_cmd('cat-file', '-e', "#{ref}:#{path}")

      execute_and_return_status(cmd).success?
    end

    def commit_exists?(commit = @commit)
      cmd = git_cmd('cat-file', '-e', commit)

      execute_and_return_status(cmd).success?
    end

    # Parse the commit time from git
    def time
      @time ||= Time.at execute(git_cmd('show', '-s', '--format=%at', @commit)).to_i
    end

    def push_url(remote)
      @push_urls ||= {}

      @push_urls[remote] ||= GitCloneUrl.parse execute git_cmd 'remote', 'get-url', '--push', @remote
    end

    # Execute a git command, passing the -C parameter if the current object has
    # the working_directory instance var set
    def git_cmd(*args)
      cmd = ['git']
      cmd += ['-C', @working_dir.to_s] if defined?(@working_dir) && !@working_dir.nil?
      cmd += args

      cmd
    end

    def self.included(base)
      base.include Subprocesses
    end

    def self.extended(base)
      base.extend Subprocesses
    end
  end
end
