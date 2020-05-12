# frozen_string_literal: true

require 'tinyci/version'
require 'tinyci/scheduler'
require 'tinyci/installer'
require 'tinyci/compactor'
require 'tinyci/log_viewer'
require 'tinyci/git_utils'
require 'tinyci/cli_ssh_delegator'
require 'optparse'
require 'pidfile'

module TinyCI
  # Defines the CLI interface. Uses OptionParser.
  class CLI
    include GitUtils

    LOGO = File.read(File.expand_path('logo.txt', __dir__)).freeze
    HIDDEN_OPTIONS = %w[
      running-remotely
    ].freeze

    def initialize(argv = ARGV)
      @argv = argv
      @opts = {}
    end

    def parse!
      if @argv[0] == '--help'
        puts BANNER
        return false
      end

      unless subcommand
        puts BANNER
        return false
      end

      global_parser.order!(global_args)
      subcommand_parsers[subcommand].order!(subcommand_args)

      @opts[:working_dir] ||= working_dir

      if @opts[:remote]
        CLISSHDelegator.new(@argv, **@opts).run!
      else
        send "do_#{subcommand}", @opts
      end
    end

    private

    def working_dir
      repo_root
    rescue TinyCI::Subprocesses::SubprocessError => e
      raise e unless e.message == '`git rev-parse --is-inside-git-dir` failed with code 32768'

      exit 1
    end

    def global_parser
      OptionParser.new do |o|
        o.banner = ''
        o.on('-q', '--[no-]quiet', 'surpress output') { |q| @opts[:quiet] = q }
        o.on('--running-remotely') { |_rr| @opts[:running_remotely] = true }
        o.on('-D=DIR', '--dir=DIR', 'specify repository location') { |d| @opts[:working_dir] = d }
        o.on('-r [REMOTE]', '--remote [REMOTE]',
             'specify remote') { |r| @opts[:remote] = r.nil? ? true : r }
      end
    end

    def global_help
      global_parser.help.split("\n").reject do |help_line|
        HIDDEN_OPTIONS.any? { |o| help_line =~ Regexp.new(o) }
      end.join("\n").strip
    end

    def subcommand_banner(subcommand_name)
      "#{LOGO % TinyCI::VERSION}\nGlobal options:\n  #{global_help}\n\n#{subcommand_name} options:"
    end

    def subcommand_parsers
      {
        'run' => OptionParser.new do |o|
          o.banner = subcommand_banner('run')
          o.on('-c <SHA>', '--commit <SHA>',
               'run against a specific commit') { |c| @opts[:commit] = c }
          o.on('-a', '--all',
               'run against all commits which have not been run against before') { |a| @opts[:all] = a }
        end,
        'install' => OptionParser.new do |o|
          o.banner = subcommand_banner('install')
          o.on('-a', '--[no-]absolute-path',
               'install hook with absolute path to specific tinyci version (not recommended)') { |v| @opts[:absolute_path] = v }
        end,
        'compact' => OptionParser.new do |o|
          o.banner = subcommand_banner('compact')
          o.on('-n', '--num-builds-to-leave <NUM>',
               'number of builds to leave in place, starting from the most recent') { |n| @opts[:num_builds_to_leave] = n }
          o.on('-b', '--builds-to-leave <BUILDS>',
               'specific build directories to leave in place, comma-separated') { |b| @opts[:builds_to_leave] = b.split(',') }
        end,
        'log' => OptionParser.new do |o|
          o.banner = subcommand_banner('log')
          o.on('-f', '--follow', 'follow the logfile') { |f| @opts[:follow] = f }
          o.on('-n <NUM>', '--num-lines <NUM>',
               'number of lines to print') { |n| @opts[:num_lines] = n.to_i }
          o.on('-c <SHA>', '--commit <SHA>',
               'run against a specific commit') { |c| @opts[:commit] = c }
        end
      }
    end

    def banner
      <<~TXT
        #{LOGO % TinyCI::VERSION}
        Global options:
            #{global_help}

        Available commands:
            run      build and test the repo
            install  install the git hook into the current repository
            compact  compress old build artifacts
            log      print logfiles
            version  print the TinyCI version number
      TXT
    end

    def subcommand_index
      @argv.index { |arg| subcommand_parsers.keys.include? arg }
    end

    def subcommand
      return nil unless subcommand_index

      @argv[subcommand_index]
    end

    def global_args
      @argv[0..subcommand_index - 1]
    end

    def subcommand_args
      @argv[subcommand_index + 1..-1]
    end

    def do_run(opts)
      if PidFile.running?
        puts 'TinyCI is already running!' unless opts[:quiet]
        return false
      end

      opts.delete(:commit) if opts[:all]

      if !opts[:commit] && !opts[:all]
        puts 'You must pass either --commit or --all, or try --help' unless opts[:quiet]
        return false
      end

      logger = MultiLogger.new(quiet: opts[:quiet])
      result = Scheduler.new(commit: opts[:commit], logger: logger,
                             working_dir: opts[:working_dir]).run!

      result
    end

    def do_install(opts)
      logger = MultiLogger.new(quiet: opts[:quiet])

      TinyCI::Installer.new(logger: logger, working_dir: opts[:working_dir],
                            absolute_path: opts[:absolute_path]).install!
    end

    def do_compact(opts)
      logger = MultiLogger.new(quiet: opts[:quiet])

      TinyCI::Compactor.new(
        logger: logger,
        working_dir: opts[:working_dir],
        num_builds_to_leave: opts[:num_builds_to_leave],
        builds_to_leave: opts[:builds_to_leave]
      ).compact!
    end

    def do_log(opts)
      TinyCI::LogViewer.new(
        working_dir: opts[:working_dir],
        commit: opts[:commit],
        follow: opts[:follow],
        num_lines: opts[:num_lines]
      ).view!
    end

    def do_version(_opts)
      puts TinyCI::VERSION

      true
    end
  end
end
