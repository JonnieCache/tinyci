# frozen_string_literal: true

require 'tinyci/git_utils'
require 'net/ssh'

module TinyCI
  # Wrapper that takes calls to {CLI} from the command line and executes them remotely via ssh, on
  # the server hosting the remote tinyci is installed to. The main purpose is to allow convenient
  # execution of `tinyci log` on the remote server.
  class CLISSHDelegator
    include GitUtils

    #
    # Constructor
    #
    # @param [Array<String>] argv The original arguments passed into {CLI}
    # @param [String] working_dir The (local) directory from which to run.
    # @param [String, Boolean] remote Which remote to ssh into. If this is set to `true` then use
    # the upstream remote for the current branch
    # @param [<Type>] **opts <description>
    #
    def initialize(argv, working_dir:, remote:, **opts)
      @argv = argv
      @working_dir = working_dir

      # Handle `remote: true` case where `--remote` switch is passed on its own without specifying a
      # remote name. The fact of this case must be stored so that the arguments to the remote
      # execution can be properly constructed.
      if remote == true
        @remote = current_tracking_remote
        @derived_remote = true
      else
        @remote = remote
        @derived_remote = false
      end
      @opts = opts
    end

    def run!
      unless remote_exists?
        warn "Remote `#{@remote}` not found"

        return false
      end

      if github_remote?
        msg = "`#{@remote}` is a github remote: #{remote_url}"
        msg += "\nPerhaps you meant to run tinyci #{@argv.first} against a different one?"

        warn msg
        return false
      end

      unless ssh_remote?
        msg = "`#{@remote}` does not appear to have an ssh remote: #{remote_url}"
        msg += "\nPerhaps you meant to run tinyci #{@argv.first} against a different one?"

        warn msg
        return false
      end

      do_tunnel!(remote_url.host, remote_url.user, command)

      true
    end

    def command
      (['tinyci', '--running-remotely', '--dir', remote_url.path] + args).join ' '
    end

    #
    # Build the argument list to execute at the remote end.
    # Main concern here is removing the arguments which are specific to remote execution, ie.
    # those relevant only to this class.
    #
    def args
      args = @argv.clone

      # since --dir always has an argument we can delete twice to get rid of the switch and the arg
      index = args.index('--dir') || args.index('-D')
      2.times { args.delete_at index } if index

      # the --remote switch can live on its own
      index = args.index('--remote') || args.index('-r')
      if index
        args.delete_at index
        args.delete_at index unless @derived_remote
      end

      args
    end

    def do_tunnel!(host, user, cmd)
      Net::SSH.start(host, user) do |ssh|
        ssh.open_channel do |ch|
          ch.exec cmd do |e_ch, success|
            abort 'could not execute command' unless success
            e_ch.on_data do |_ch, data|
              print data
            end
            e_ch.on_extended_data do |_ch, _type, data|
              warn data
            end
          end
        end

        ssh.loop
      end
    end
  end
end
